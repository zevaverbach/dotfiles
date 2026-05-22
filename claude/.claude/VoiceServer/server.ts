#!/usr/bin/env bun
/**
 * Voice Server - Personal AI Voice notification server using ElevenLabs TTS
 *
 * Architecture: Pure pass-through. All voice config comes from settings.json.
 * The server has zero hardcoded voice parameters.
 *
 * Config resolution (3-tier):
 *   1. Caller sends voice_settings in request body → use directly (pass-through)
 *   2. Caller sends voice_id → look up in settings.json daidentity.voices → use those settings
 *   3. Neither → use settings.json daidentity.voices.main as default
 *
 * Pronunciation preprocessing: loads pronunciations.json and applies
 * word-boundary replacements before sending text to ElevenLabs TTS.
 */

import { serve } from "bun";
import { spawn } from "child_process";
import { homedir } from "os";
import { join } from "path";
import { existsSync, readFileSync, appendFileSync } from "fs";

// Load .env from user home directory
const envPath = join(homedir(), '.env');
if (existsSync(envPath)) {
  const envContent = await Bun.file(envPath).text();
  envContent.split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value && !key.startsWith('#')) {
      process.env[key.trim()] = value.trim();
    }
  });
}

const PORT = parseInt(process.env.PORT || "8888");
const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY;
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

if (!OPENAI_API_KEY && !ELEVENLABS_API_KEY) {
  console.warn('⚠️  No cloud TTS API key found. Set OPENAI_API_KEY or ELEVENLABS_API_KEY for cloud fallback.');
}

// ==========================================================================
// KittenTTS Local Worker — stdin/stdout Python subprocess
// ==========================================================================

const KITTEN_VENV = join(import.meta.dir, '.kitten-venv');
const KITTEN_PYTHON = join(KITTEN_VENV, 'bin', 'python3');
const KITTEN_WORKER_SCRIPT = join(import.meta.dir, 'kitten_worker.py');

let kittenProc: ReturnType<typeof Bun.spawn> | null = null;
let kittenReady = false;
let kittenModel = 'nano';

// Auto-restart state — exponential backoff: 2s, 4s, 8s, then give up
let kittenRestartAttempts = 0;
const KITTEN_MAX_RESTARTS = 3;
const KITTEN_BASE_BACKOFF_MS = 2000;

// Queue for pending KittenTTS requests (serialize access to stdin/stdout)
let kittenRequestQueue: Array<{
  resolve: (result: any) => void;
  reject: (error: Error) => void;
}> = [];
let kittenResponseBuffer = '';

function startKittenWorker(): void {
  if (!existsSync(KITTEN_PYTHON) || !existsSync(KITTEN_WORKER_SCRIPT)) {
    console.warn('🐱 KittenTTS not available (run setup_kitten.sh to install)');
    return;
  }

  try {
    kittenProc = Bun.spawn([KITTEN_PYTHON, KITTEN_WORKER_SCRIPT], {
      stdin: 'pipe',
      stdout: 'pipe',
      stderr: 'inherit',  // Worker logs go to server stderr
      env: { ...process.env, KITTEN_TTS_MODEL: kittenModel },
    });

    // Read stdout line-by-line for responses
    const reader = kittenProc.stdout.getReader();
    const decoder = new TextDecoder();

    (async () => {
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          kittenResponseBuffer += decoder.decode(value, { stream: true });

          // Process complete lines
          let newlineIdx;
          while ((newlineIdx = kittenResponseBuffer.indexOf('\n')) !== -1) {
            const line = kittenResponseBuffer.slice(0, newlineIdx).trim();
            kittenResponseBuffer = kittenResponseBuffer.slice(newlineIdx + 1);

            if (!line) continue;

            try {
              const msg = JSON.parse(line);

              if (msg.status === 'ready') {
                kittenReady = true;
                kittenRestartAttempts = 0;  // Reset backoff on successful start
                kittenModel = msg.model || 'nano';
                console.log(`🐱 KittenTTS worker ready (model: ${kittenModel}, loaded in ${msg.load_time}s)`);
                continue;
              }

              // Resolve the next pending request
              const pending = kittenRequestQueue.shift();
              if (pending) {
                if (msg.status === 'ok') {
                  pending.resolve(msg);
                } else {
                  pending.reject(new Error(msg.message || 'KittenTTS error'));
                }
              }
            } catch (e) {
              console.error('🐱 Failed to parse KittenTTS response:', line);
            }
          }
        }
      } catch (e) {
        console.error('🐱 KittenTTS stdout reader error:', e);
      }

      // Worker exited — reject any pending requests and attempt restart
      kittenReady = false;
      kittenProc = null;
      for (const pending of kittenRequestQueue) {
        pending.reject(new Error('KittenTTS worker exited'));
      }
      kittenRequestQueue = [];
      kittenResponseBuffer = '';

      if (kittenRestartAttempts < KITTEN_MAX_RESTARTS) {
        kittenRestartAttempts++;
        const backoffMs = KITTEN_BASE_BACKOFF_MS * Math.pow(2, kittenRestartAttempts - 1);
        console.warn(`🐱 KittenTTS worker exited — restarting in ${backoffMs / 1000}s (attempt ${kittenRestartAttempts}/${KITTEN_MAX_RESTARTS})`);
        setTimeout(() => startKittenWorker(), backoffMs);
      } else {
        console.error(`🐱 KittenTTS worker exited — giving up after ${KITTEN_MAX_RESTARTS} restart attempts. Cloud TTS will be used.`);
      }
    })();

    console.log('🐱 KittenTTS worker starting...');
  } catch (error) {
    console.error('🐱 Failed to start KittenTTS worker:', error);
  }
}

async function kittenGenerate(text: string, voice?: string, speed?: number): Promise<string> {
  if (!kittenProc || !kittenReady) {
    throw new Error('KittenTTS worker not available');
  }

  const request = JSON.stringify({ text, voice: voice || 'Jasper', ...(speed && { speed }) }) + '\n';

  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      // Remove from queue on timeout
      const idx = kittenRequestQueue.findIndex(p => p.resolve === resolveWrapper);
      if (idx !== -1) kittenRequestQueue.splice(idx, 1);
      reject(new Error('KittenTTS generation timed out (30s)'));
    }, 30000);

    const resolveWrapper = (result: any) => {
      clearTimeout(timeout);
      resolve(result.path);
    };
    const rejectWrapper = (error: Error) => {
      clearTimeout(timeout);
      reject(error);
    };

    kittenRequestQueue.push({ resolve: resolveWrapper, reject: rejectWrapper });
    kittenProc!.stdin.write(request);
  });
}

// Start KittenTTS worker at server boot
startKittenWorker();

// OpenAI voice mapping: map ElevenLabs voice IDs to OpenAI voices for compatibility
const OPENAI_DEFAULT_VOICE = 'nova';
const openaiVoiceMap: Record<string, string> = {};  // populated from settings if needed

// ==========================================================================
// Spend Tracking — persistent JSONL log, 30-day rolling window
// ==========================================================================

const SPEND_LOG = join(import.meta.dir, 'spend.jsonl');

// OpenAI TTS pricing per character
const COST_PER_CHAR_TTS1 = 0.015 / 1000;       // $0.015 per 1K chars
const COST_PER_CHAR_TTS1_HD = 0.030 / 1000;     // $0.030 per 1K chars

function trackSpend(text: string, model: string = 'tts-1'): void {
  const chars = text.length;
  const costPerChar = model === 'tts-1-hd' ? COST_PER_CHAR_TTS1_HD : COST_PER_CHAR_TTS1;
  const cost = chars * costPerChar;
  const entry = JSON.stringify({ ts: new Date().toISOString(), chars, cost, model }) + '\n';
  try { appendFileSync(SPEND_LOG, entry); } catch { /* ignore */ }
}

function getSpend30d(): { totalChars: number; totalCostUsd: number; requestCount: number } {
  try {
    if (!existsSync(SPEND_LOG)) return { totalChars: 0, totalCostUsd: 0, requestCount: 0 };
    const content = readFileSync(SPEND_LOG, 'utf-8');
    const cutoff = Date.now() - 30 * 24 * 60 * 60 * 1000;
    let totalChars = 0, totalCostUsd = 0, requestCount = 0;
    for (const line of content.split('\n')) {
      if (!line.trim()) continue;
      try {
        const entry = JSON.parse(line);
        if (new Date(entry.ts).getTime() >= cutoff) {
          totalChars += entry.chars || 0;
          totalCostUsd += entry.cost || 0;
          requestCount++;
        }
      } catch { /* skip malformed lines */ }
    }
    return { totalChars, totalCostUsd: Math.round(totalCostUsd * 10000) / 10000, requestCount };
  } catch {
    return { totalChars: 0, totalCostUsd: 0, requestCount: 0 };
  }
}

// ==========================================================================
// Pronunciation System
// ==========================================================================

interface PronunciationEntry {
  term: string;
  phonetic: string;
  note?: string;
}

interface PronunciationConfig {
  replacements: PronunciationEntry[];
}

// Compiled pronunciation rules (loaded once at startup)
interface CompiledRule {
  regex: RegExp;
  phonetic: string;
}

let pronunciationRules: CompiledRule[] = [];

// Load and compile pronunciation rules from pronunciations.json
function loadPronunciations(): void {
  const pronPath = join(import.meta.dir, 'pronunciations.json');
  try {
    if (!existsSync(pronPath)) {
      console.warn('⚠️  No pronunciations.json found — TTS will use default pronunciations');
      return;
    }
    const content = readFileSync(pronPath, 'utf-8');
    const config: PronunciationConfig = JSON.parse(content);

    pronunciationRules = config.replacements.map(entry => ({
      // Word-boundary matching: \b ensures "{DAIDENTITY.NAME}" matches but "Kaiser" doesn't
      regex: new RegExp(`\\b${escapeRegex(entry.term)}\\b`, 'g'),
      phonetic: entry.phonetic,
    }));

    console.log(`📖 Loaded ${pronunciationRules.length} pronunciation rules`);
    for (const entry of config.replacements) {
      console.log(`   ${entry.term} → ${entry.phonetic} (${entry.note || ''})`);
    }
  } catch (error) {
    console.error('⚠️  Failed to load pronunciations.json:', error);
  }
}

// Escape special regex characters in a literal string
function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Apply all pronunciation replacements to text before TTS
function applyPronunciations(text: string): string {
  let result = text;
  for (const rule of pronunciationRules) {
    result = result.replace(rule.regex, rule.phonetic);
  }
  return result;
}

// Load pronunciations at startup
loadPronunciations();

// ==========================================================================
// Mute System — server-side TTS kill switch + auto-mute by session count
// ==========================================================================

let muted = false;           // Manual mute toggle
let autoMuteEnabled = false; // Auto-mute: only speak when multiple sessions detected
const AUTO_MUTE_THRESHOLD = 2; // Minimum concurrent Claude sessions to allow voice

// Count concurrent Claude Code CLI sessions (not desktop app, not subprocesses)
async function countClaudeSessions(): Promise<number> {
  try {
    // Use ps to get full command lines — pgrep -af on macOS doesn't reliably show args
    const proc = Bun.spawn(['ps', '-eo', 'args='], { stdout: 'pipe', stderr: 'pipe' });
    const output = await new Response(proc.stdout).text();
    await proc.exited;

    const lines = output.split('\n').filter(line => {
      const trimmed = line.trim();
      if (!trimmed) return false;
      // Match "claude" CLI processes: bare "claude" or "claude --flags..."
      // Exclude: Claude.app (desktop), VoiceServer, PAI tools, statusline, ps/grep
      if (trimmed.includes('Claude.app')) return false;
      if (trimmed.includes('VoiceServer')) return false;
      if (trimmed.includes('pai.ts')) return false;
      if (trimmed.includes('statusline')) return false;
      if (trimmed.includes('/ps ') || trimmed.includes('grep')) return false;
      // Must be an actual claude CLI invocation
      return trimmed === 'claude' || trimmed.startsWith('claude ');
    });

    console.log(`🔍 Session detection: found ${lines.length} Claude CLI session(s)`);
    for (const line of lines) {
      console.log(`   ${line.substring(0, 80)}`);
    }

    return lines.length;
  } catch {
    return 1; // On error, assume single session (safe default: allow voice)
  }
}

// Check if voice should be suppressed
async function isVoiceSuppressed(): Promise<{ suppressed: boolean; reason?: string }> {
  if (muted) {
    return { suppressed: true, reason: 'manually muted' };
  }

  if (autoMuteEnabled) {
    const sessions = await countClaudeSessions();
    if (sessions < AUTO_MUTE_THRESHOLD) {
      return { suppressed: true, reason: `auto-mute: ${sessions} session(s) < threshold ${AUTO_MUTE_THRESHOLD}` };
    }
    console.log(`🔊 Auto-mute: ${sessions} session(s) >= threshold ${AUTO_MUTE_THRESHOLD}, allowing voice`);
  }

  return { suppressed: false };
}

// ==========================================================================
// Voice Configuration — Single Source of Truth: settings.json
// ==========================================================================

// ElevenLabs voice_settings fields (sent to their API)
interface ElevenLabsVoiceSettings {
  stability: number;
  similarity_boost: number;
  style?: number;
  speed?: number;
  use_speaker_boost?: boolean;
}

// A voice entry from settings.json daidentity.voices.*
interface VoiceEntry {
  voiceId: string;
  voiceName?: string;
  stability: number;
  similarity_boost: number;
  style: number;
  speed: number;
  use_speaker_boost: boolean;
  volume: number;
}

// Loaded config from settings.json
interface LoadedVoiceConfig {
  defaultVoiceId: string;
  voices: Record<string, VoiceEntry>;     // keyed by name ("main", "algorithm")
  voicesByVoiceId: Record<string, VoiceEntry>;  // keyed by voiceId for lookup
  desktopNotifications: boolean;  // whether to show macOS notification banners
}

// Last-resort defaults if settings.json is entirely missing or unparseable
const FALLBACK_VOICE_SETTINGS: ElevenLabsVoiceSettings = {
  stability: 0.5,
  similarity_boost: 0.75,
  style: 0.0,
  speed: 1.0,
  use_speaker_boost: true,
};
const FALLBACK_VOLUME = 1.0;

// Load voice configuration from settings.json (cached at startup)
function loadVoiceConfig(): LoadedVoiceConfig {
  const settingsPath = join(homedir(), '.claude', 'settings.json');

  try {
    if (!existsSync(settingsPath)) {
      console.warn('⚠️  settings.json not found — using fallback voice defaults');
      return { defaultVoiceId: '', voices: {}, voicesByVoiceId: {}, desktopNotifications: true };
    }

    const content = readFileSync(settingsPath, 'utf-8');
    const settings = JSON.parse(content);
    const daidentity = settings.daidentity || {};
    const voicesSection = daidentity.voices || {};
    const desktopNotifications = settings.notifications?.desktop?.enabled !== false;

    // Build lookup maps
    const voices: Record<string, VoiceEntry> = {};
    const voicesByVoiceId: Record<string, VoiceEntry> = {};

    for (const [name, config] of Object.entries(voicesSection)) {
      const entry = config as any;
      if (entry.voiceId) {
        const voiceEntry: VoiceEntry = {
          voiceId: entry.voiceId,
          voiceName: entry.voiceName,
          stability: entry.stability ?? 0.5,
          similarity_boost: entry.similarity_boost ?? entry.similarityBoost ?? 0.75,
          style: entry.style ?? 0.0,
          speed: entry.speed ?? 1.0,
          use_speaker_boost: entry.use_speaker_boost ?? entry.useSpeakerBoost ?? true,
          volume: entry.volume ?? 1.0,
        };
        voices[name] = voiceEntry;
        voicesByVoiceId[entry.voiceId] = voiceEntry;
      }
    }

    // Default voice ID from settings
    const defaultVoiceId = voices.main?.voiceId || daidentity.mainDAVoiceID || '';

    const voiceNames = Object.keys(voices);
    console.log(`✅ Loaded ${voiceNames.length} voice config(s) from settings.json: ${voiceNames.join(', ')}`);
    for (const [name, entry] of Object.entries(voices)) {
      console.log(`   ${name}: ${entry.voiceName || entry.voiceId} (speed: ${entry.speed}, stability: ${entry.stability})`);
    }

    return { defaultVoiceId, voices, voicesByVoiceId, desktopNotifications };
  } catch (error) {
    console.error('⚠️  Failed to load settings.json voice config:', error);
    return { defaultVoiceId: '', voices: {}, voicesByVoiceId: {}, desktopNotifications: true };
  }
}

// Load config at startup
const voiceConfig = loadVoiceConfig();
const DEFAULT_VOICE_ID = voiceConfig.defaultVoiceId || process.env.ELEVENLABS_VOICE_ID || "s3TPKV1kjDlVtZbl4Ksh";

// Look up a voice entry by voice ID
function lookupVoiceByVoiceId(voiceId: string): VoiceEntry | null {
  return voiceConfig.voicesByVoiceId[voiceId] || null;
}

// Get ElevenLabs voice settings for a voice entry
function voiceEntryToSettings(entry: VoiceEntry): ElevenLabsVoiceSettings {
  return {
    stability: entry.stability,
    similarity_boost: entry.similarity_boost,
    style: entry.style,
    speed: entry.speed,
    use_speaker_boost: entry.use_speaker_boost,
  };
}

// Emotional markers for dynamic voice adjustment (overlay-only — modifies stability + similarity_boost)
interface EmotionalOverlay {
  stability: number;
  similarity_boost: number;
}

// 13 Emotional Presets - Expanded Prosody System
// These OVERLAY onto resolved voice settings, not replace them
const EMOTIONAL_PRESETS: Record<string, EmotionalOverlay> = {
  // High Energy / Positive
  'excited': { stability: 0.7, similarity_boost: 0.9 },
  'celebration': { stability: 0.65, similarity_boost: 0.85 },
  'insight': { stability: 0.55, similarity_boost: 0.8 },
  'creative': { stability: 0.5, similarity_boost: 0.75 },

  // Success / Achievement
  'success': { stability: 0.6, similarity_boost: 0.8 },
  'progress': { stability: 0.55, similarity_boost: 0.75 },

  // Analysis / Investigation
  'investigating': { stability: 0.6, similarity_boost: 0.85 },
  'debugging': { stability: 0.55, similarity_boost: 0.8 },
  'learning': { stability: 0.5, similarity_boost: 0.75 },

  // Thoughtful / Careful
  'pondering': { stability: 0.65, similarity_boost: 0.8 },
  'focused': { stability: 0.7, similarity_boost: 0.85 },
  'caution': { stability: 0.4, similarity_boost: 0.6 },

  // Urgent / Critical
  'urgent': { stability: 0.3, similarity_boost: 0.9 },
};

// Escape special characters for AppleScript
function escapeForAppleScript(input: string): string {
  return input.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

// Extract emotional marker from message
function extractEmotionalMarker(message: string): { cleaned: string; emotion?: string } {
  const emojiToEmotion: Record<string, string> = {
    '\u{1F4A5}': 'excited',
    '\u{1F389}': 'celebration',
    '\u{1F4A1}': 'insight',
    '\u{1F3A8}': 'creative',
    '\u{2728}': 'success',
    '\u{1F4C8}': 'progress',
    '\u{1F50D}': 'investigating',
    '\u{1F41B}': 'debugging',
    '\u{1F4DA}': 'learning',
    '\u{1F914}': 'pondering',
    '\u{1F3AF}': 'focused',
    '\u{26A0}\u{FE0F}': 'caution',
    '\u{1F6A8}': 'urgent'
  };

  const emotionMatch = message.match(/\[(\u{1F4A5}|\u{1F389}|\u{1F4A1}|\u{1F3A8}|\u{2728}|\u{1F4C8}|\u{1F50D}|\u{1F41B}|\u{1F4DA}|\u{1F914}|\u{1F3AF}|\u{26A0}\u{FE0F}|\u{1F6A8})\s+(\w+)\]/u);
  if (emotionMatch) {
    const emoji = emotionMatch[1];
    const emotionName = emotionMatch[2].toLowerCase();

    if (emojiToEmotion[emoji] === emotionName) {
      return {
        cleaned: message.replace(emotionMatch[0], '').trim(),
        emotion: emotionName
      };
    }
  }

  return { cleaned: message };
}

// Sanitize input for TTS and notifications
function sanitizeForSpeech(input: string): string {
  const cleaned = input
    .replace(/<script/gi, '')
    .replace(/\.\.\//g, '')
    .replace(/[;&|><`$\\]/g, '')
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/\*([^*]+)\*/g, '$1')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/#{1,6}\s+/g, '')
    .trim()
    .substring(0, 500);

  return cleaned;
}

// Validate user input
function validateInput(input: any): { valid: boolean; error?: string; sanitized?: string } {
  if (!input || typeof input !== 'string') {
    return { valid: false, error: 'Invalid input type' };
  }

  if (input.length > 500) {
    return { valid: false, error: 'Message too long (max 500 characters)' };
  }

  const sanitized = sanitizeForSpeech(input);

  if (!sanitized || sanitized.length === 0) {
    return { valid: false, error: 'Message contains no valid content after sanitization' };
  }

  return { valid: true, sanitized };
}

// Generate speech result — either a local file path (KittenTTS) or an ArrayBuffer (cloud)
type SpeechResult =
  | { type: 'file'; path: string }
  | { type: 'buffer'; data: ArrayBuffer };

// Generate speech using KittenTTS (local) → OpenAI → ElevenLabs
async function generateSpeech(
  text: string,
  voiceId: string,
  voiceSettings: ElevenLabsVoiceSettings
): Promise<SpeechResult> {
  // Apply pronunciation replacements before sending to TTS
  const pronouncedText = applyPronunciations(text);
  if (pronouncedText !== text) {
    console.log(`📖 Pronunciation: "${text}" → "${pronouncedText}"`);
  }

  // Try KittenTTS first (local, free, no API key needed)
  if (kittenReady) {
    try {
      const wavPath = await kittenGenerate(pronouncedText, undefined, voiceSettings.speed);
      console.log(`🐱 KittenTTS generated: ${wavPath}`);
      return { type: 'file', path: wavPath };
    } catch (error: any) {
      console.warn(`🐱 KittenTTS failed, falling back to cloud: ${error.message}`);
    }
  }

  // Try OpenAI
  if (OPENAI_API_KEY) {
    return { type: 'buffer', data: await generateSpeechOpenAI(pronouncedText, voiceId, voiceSettings) };
  }

  // Fall back to ElevenLabs
  if (ELEVENLABS_API_KEY) {
    return { type: 'buffer', data: await generateSpeechElevenLabs(pronouncedText, voiceId, voiceSettings) };
  }

  throw new Error('No TTS provider available (KittenTTS not ready, no API keys configured)');
}

// OpenAI TTS — uses tts-1 for low latency, maps speed from voice settings
async function generateSpeechOpenAI(
  text: string,
  voiceId: string,
  voiceSettings: ElevenLabsVoiceSettings
): Promise<ArrayBuffer> {
  const openaiVoice = openaiVoiceMap[voiceId] || OPENAI_DEFAULT_VOICE;
  const speed = Math.max(0.25, Math.min(4.0, voiceSettings.speed || 1.0));

  console.log(`🔊 OpenAI TTS: voice=${openaiVoice}, speed=${speed}`);
  trackSpend(text, 'tts-1');

  const response = await fetch('https://api.openai.com/v1/audio/speech', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'tts-1',
      input: text,
      voice: openaiVoice,
      speed,
      response_format: 'mp3',
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI TTS error: ${response.status} - ${errorText}`);
  }

  return await response.arrayBuffer();
}

// ElevenLabs TTS — original implementation (fallback)
async function generateSpeechElevenLabs(
  text: string,
  voiceId: string,
  voiceSettings: ElevenLabsVoiceSettings
): Promise<ArrayBuffer> {
  const url = `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Accept': 'audio/mpeg',
      'Content-Type': 'application/json',
      'xi-api-key': ELEVENLABS_API_KEY!,
    },
    body: JSON.stringify({
      text,
      model_id: 'eleven_turbo_v2_5',
      voice_settings: voiceSettings,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`ElevenLabs API error: ${response.status} - ${errorText}`);
  }

  return await response.arrayBuffer();
}

// Play audio using afplay (macOS) — accepts either a file path or an ArrayBuffer
async function playAudio(source: SpeechResult, volume: number = FALLBACK_VOLUME): Promise<void> {
  let filePath: string;
  let needsCleanup: boolean;

  if (source.type === 'file') {
    filePath = source.path;
    needsCleanup = true;  // KittenTTS temp files should be cleaned up
  } else {
    filePath = `/tmp/voice-${Date.now()}.mp3`;
    await Bun.write(filePath, source.data);
    needsCleanup = true;
  }

  return new Promise((resolve, reject) => {
    const proc = spawn('/usr/bin/afplay', ['-v', volume.toString(), filePath]);

    proc.on('error', (error) => {
      console.error('Error playing audio:', error);
      reject(error);
    });

    proc.on('exit', (code) => {
      if (needsCleanup) spawn('/bin/rm', [filePath]);
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`afplay exited with code ${code}`));
      }
    });
  });
}

// Spawn a process safely
function spawnSafe(command: string, args: string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn(command, args);

    proc.on('error', (error) => {
      console.error(`Error spawning ${command}:`, error);
      reject(error);
    });

    proc.on('exit', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`${command} exited with code ${code}`));
      }
    });
  });
}

// ==========================================================================
// Core: Send notification with 3-tier voice settings resolution
// ==========================================================================

/**
 * Send macOS notification with voice.
 *
 * Voice settings resolution (3-tier):
 *   1. callerVoiceSettings provided → use directly (pass-through)
 *   2. voiceId provided → look up in settings.json → use those settings
 *   3. Neither → use settings.json voices.main defaults
 *
 * Emotional presets overlay stability + similarity_boost onto resolved settings.
 * Volume is resolved separately: caller → voice entry → main → 1.0 fallback.
 */
async function sendNotification(
  title: string,
  message: string,
  voiceEnabled = true,
  voiceId: string | null = null,
  callerVoiceSettings?: Partial<ElevenLabsVoiceSettings> | null,
  callerVolume?: number | null,
): Promise<{ voicePlayed: boolean; voiceError?: string }> {
  const titleValidation = validateInput(title);
  const messageValidation = validateInput(message);

  if (!titleValidation.valid) {
    throw new Error(`Invalid title: ${titleValidation.error}`);
  }

  if (!messageValidation.valid) {
    throw new Error(`Invalid message: ${messageValidation.error}`);
  }

  const safeTitle = titleValidation.sanitized!;
  let safeMessage = messageValidation.sanitized!;

  const { cleaned, emotion } = extractEmotionalMarker(safeMessage);
  safeMessage = cleaned;

  // Generate and play voice using ElevenLabs
  let voicePlayed = false;
  let voiceError: string | undefined;

  // Check mute state before TTS
  const muteCheck = await isVoiceSuppressed();
  if (muteCheck.suppressed) {
    console.log(`🔇 Voice suppressed: ${muteCheck.reason}`);
    voiceEnabled = false;
  }

  if (voiceEnabled && (kittenReady || OPENAI_API_KEY || ELEVENLABS_API_KEY)) {
    try {
      const voice = voiceId || DEFAULT_VOICE_ID;

      // 3-tier voice settings resolution
      let resolvedSettings: ElevenLabsVoiceSettings;
      let resolvedVolume: number;

      if (callerVoiceSettings && Object.keys(callerVoiceSettings).length > 0) {
        // Tier 1: Caller provided explicit voice_settings → pass through
        resolvedSettings = {
          stability: callerVoiceSettings.stability ?? FALLBACK_VOICE_SETTINGS.stability,
          similarity_boost: callerVoiceSettings.similarity_boost ?? FALLBACK_VOICE_SETTINGS.similarity_boost,
          style: callerVoiceSettings.style ?? FALLBACK_VOICE_SETTINGS.style,
          speed: callerVoiceSettings.speed ?? FALLBACK_VOICE_SETTINGS.speed,
          use_speaker_boost: callerVoiceSettings.use_speaker_boost ?? FALLBACK_VOICE_SETTINGS.use_speaker_boost,
        };
        resolvedVolume = callerVolume ?? FALLBACK_VOLUME;
        console.log(`🔗 Voice settings: pass-through from caller`);
      } else {
        // Tier 2/3: Look up by voiceId, fall back to main
        const voiceEntry = lookupVoiceByVoiceId(voice) || voiceConfig.voices.main;
        if (voiceEntry) {
          resolvedSettings = voiceEntryToSettings(voiceEntry);
          resolvedVolume = callerVolume ?? voiceEntry.volume ?? FALLBACK_VOLUME;
          console.log(`📋 Voice settings: from settings.json (${voiceEntry.voiceName || voice})`);
        } else {
          resolvedSettings = { ...FALLBACK_VOICE_SETTINGS };
          resolvedVolume = callerVolume ?? FALLBACK_VOLUME;
          console.log(`⚠️  Voice settings: fallback defaults (no config found for ${voice})`);
        }
      }

      // Emotional preset overlay — modifies stability + similarity_boost only
      if (emotion && EMOTIONAL_PRESETS[emotion]) {
        resolvedSettings = {
          ...resolvedSettings,
          stability: EMOTIONAL_PRESETS[emotion].stability,
          similarity_boost: EMOTIONAL_PRESETS[emotion].similarity_boost,
        };
        console.log(`🎭 Emotion overlay: ${emotion}`);
      }

      console.log(`🎙️  Generating speech (voice: ${voice}, speed: ${resolvedSettings.speed}, stability: ${resolvedSettings.stability}, boost: ${resolvedSettings.similarity_boost}, style: ${resolvedSettings.style}, volume: ${resolvedVolume})`);

      const speechResult = await generateSpeech(safeMessage, voice, resolvedSettings);
      await playAudio(speechResult, resolvedVolume);
      voicePlayed = true;
    } catch (error: any) {
      console.error("Failed to generate/play speech:", error);
      voiceError = error.message || "TTS generation failed";
    }
  }

  // Display macOS notification (can be disabled via settings.json: notifications.desktop.enabled: false)
  if (voiceConfig.desktopNotifications) {
    try {
      const escapedTitle = escapeForAppleScript(safeTitle);
      const escapedMessage = escapeForAppleScript(safeMessage);
      const script = `display notification "${escapedMessage}" with title "${escapedTitle}" sound name ""`;
      await spawnSafe('/usr/bin/osascript', ['-e', script]);
    } catch (error) {
      console.error("Notification display error:", error);
    }
  }

  return { voicePlayed, voiceError };
}

// Rate limiting
const requestCounts = new Map<string, { count: number; resetTime: number }>();
const RATE_LIMIT = 10;
const RATE_WINDOW = 60000;

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const record = requestCounts.get(ip);

  if (!record || now > record.resetTime) {
    requestCounts.set(ip, { count: 1, resetTime: now + RATE_WINDOW });
    return true;
  }

  if (record.count >= RATE_LIMIT) {
    return false;
  }

  record.count++;
  return true;
}

// Start HTTP server
const server = serve({
  port: PORT,
  async fetch(req) {
    const url = new URL(req.url);

    const clientIp = req.headers.get('x-forwarded-for') || 'localhost';

    const corsHeaders = {
      "Access-Control-Allow-Origin": "http://localhost",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type"
    };

    if (req.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders, status: 204 });
    }

    // Rate limit TTS endpoints only — admin/control endpoints are exempt
    const adminPaths = ['/mute', '/unmute', '/auto-mute', '/mute-status', '/health', '/spend'];
    if (!adminPaths.includes(url.pathname) && !checkRateLimit(clientIp)) {
      return new Response(
        JSON.stringify({ status: "error", message: "Rate limit exceeded" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 429
        }
      );
    }

    if (url.pathname === "/notify" && req.method === "POST") {
      try {
        const data = await req.json();
        const title = data.title || "PAI Notification";
        const message = data.message || "Task completed";
        const voiceEnabled = data.voice_enabled !== false;
        const voiceId = data.voice_id || data.voice_name || null;
        const voiceSettings = data.voice_settings || null;
        const volume = data.volume ?? null;

        if (voiceId && typeof voiceId !== 'string') {
          throw new Error('Invalid voice_id');
        }

        console.log(`📨 Notification: "${title}" - "${message}" (voice: ${voiceEnabled}, voiceId: ${voiceId || DEFAULT_VOICE_ID})`);

        const result = await sendNotification(title, message, voiceEnabled, voiceId, voiceSettings, volume);

        if (voiceEnabled && !result.voicePlayed && result.voiceError) {
          return new Response(
            JSON.stringify({ status: "error", message: `TTS failed: ${result.voiceError}`, notification_sent: true }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
              status: 502
            }
          );
        }

        return new Response(
          JSON.stringify({ status: "success", message: "Notification sent" }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200
          }
        );
      } catch (error: any) {
        console.error("Notification error:", error);
        return new Response(
          JSON.stringify({ status: "error", message: error.message || "Internal server error" }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: error.message?.includes('Invalid') ? 400 : 500
          }
        );
      }
    }

    // /notify/personality — compatibility shim for callers using the old Qwen3-TTS endpoint
    // Personality fields are Qwen3-specific; for ElevenLabs, we just speak with default voice
    if (url.pathname === "/notify/personality" && req.method === "POST") {
      try {
        const data = await req.json();
        const message = data.message || "Notification";

        console.log(`🎭 Personality notification: "${message}"`);

        await sendNotification("PAI Notification", message, true, null);

        return new Response(
          JSON.stringify({ status: "success", message: "Personality notification sent" }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200
          }
        );
      } catch (error: any) {
        console.error("Personality notification error:", error);
        return new Response(
          JSON.stringify({ status: "error", message: error.message || "Internal server error" }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: error.message?.includes('Invalid') ? 400 : 500
          }
        );
      }
    }

    if (url.pathname === "/pai" && req.method === "POST") {
      try {
        const data = await req.json();
        const title = data.title || "PAI Assistant";
        const message = data.message || "Task completed";

        console.log(`🤖 PAI notification: "${title}" - "${message}"`);

        await sendNotification(title, message, true, null);

        return new Response(
          JSON.stringify({ status: "success", message: "PAI notification sent" }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200
          }
        );
      } catch (error: any) {
        console.error("PAI notification error:", error);
        return new Response(
          JSON.stringify({ status: "error", message: error.message || "Internal server error" }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: error.message?.includes('Invalid') ? 400 : 500
          }
        );
      }
    }

    // ==========================================================================
    // Mute controls
    // ==========================================================================

    if (url.pathname === "/mute" && req.method === "POST") {
      muted = true;
      console.log('🔇 Voice MUTED (manual)');
      return new Response(
        JSON.stringify({ status: "success", muted: true, auto_mute: autoMuteEnabled }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    if (url.pathname === "/unmute" && req.method === "POST") {
      muted = false;
      console.log('🔊 Voice UNMUTED');
      return new Response(
        JSON.stringify({ status: "success", muted: false, auto_mute: autoMuteEnabled }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    if (url.pathname === "/auto-mute" && req.method === "POST") {
      try {
        const data = await req.json().catch(() => ({}));
        if (typeof data.enabled === 'boolean') {
          autoMuteEnabled = data.enabled;
        } else {
          autoMuteEnabled = !autoMuteEnabled; // toggle
        }
        const sessions = await countClaudeSessions();
        console.log(`🔄 Auto-mute ${autoMuteEnabled ? 'ENABLED' : 'DISABLED'} (current sessions: ${sessions}, threshold: ${AUTO_MUTE_THRESHOLD})`);
        return new Response(
          JSON.stringify({
            status: "success",
            auto_mute: autoMuteEnabled,
            muted,
            current_sessions: sessions,
            threshold: AUTO_MUTE_THRESHOLD,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
        );
      } catch (error: any) {
        return new Response(
          JSON.stringify({ status: "error", message: error.message }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
        );
      }
    }

    if (url.pathname === "/mute-status") {
      const sessions = autoMuteEnabled ? await countClaudeSessions() : null;
      return new Response(
        JSON.stringify({
          muted,
          auto_mute: autoMuteEnabled,
          ...(sessions !== null && { current_sessions: sessions, threshold: AUTO_MUTE_THRESHOLD }),
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    if (url.pathname === "/spend") {
      const data = getSpend30d();
      return new Response(
        JSON.stringify({
          total_chars: data.totalChars,
          total_cost_usd: data.totalCostUsd,
          request_count: data.requestCount,
          window: "30d",
          primary_provider: kittenReady ? "KittenTTS (local, $0)" : OPENAI_API_KEY ? "OpenAI" : "ElevenLabs",
          cloud_spend_provider: OPENAI_API_KEY ? "OpenAI" : "ElevenLabs",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200
        }
      );
    }

    if (url.pathname === "/health") {
      const primaryProvider = kittenReady ? "KittenTTS" : OPENAI_API_KEY ? "OpenAI" : "ElevenLabs";
      return new Response(
        JSON.stringify({
          status: "healthy",
          port: PORT,
          voice_system: primaryProvider,
          kitten_tts: { available: kittenReady, model: kittenModel },
          cloud_fallback: OPENAI_API_KEY ? "OpenAI" : ELEVENLABS_API_KEY ? "ElevenLabs" : "none",
          default_voice_id: OPENAI_API_KEY ? OPENAI_DEFAULT_VOICE : DEFAULT_VOICE_ID,
          api_key_configured: !!(OPENAI_API_KEY || ELEVENLABS_API_KEY),
          pronunciation_rules: pronunciationRules.length,
          configured_voices: Object.keys(voiceConfig.voices),
          muted,
          auto_mute: autoMuteEnabled,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200
        }
      );
    }

    return new Response("Voice Server - POST to /notify, /notify/personality, or /pai", {
      headers: corsHeaders,
      status: 200
    });
  },
});

const cloudProvider = OPENAI_API_KEY ? 'OpenAI' : ELEVENLABS_API_KEY ? 'ElevenLabs' : 'none';
console.log(`🚀 Voice Server running on port ${PORT}`);
console.log(`🐱 KittenTTS: ${existsSync(KITTEN_PYTHON) ? 'installed (starting worker...)' : 'not installed (run setup_kitten.sh)'}`);
console.log(`☁️  Cloud fallback: ${cloudProvider}${OPENAI_API_KEY ? ` (voice: ${OPENAI_DEFAULT_VOICE})` : ELEVENLABS_API_KEY ? ` (voice: ${DEFAULT_VOICE_ID})` : ''}`);
console.log(`📡 POST to http://localhost:${PORT}/notify`);
console.log(`🔒 Security: CORS restricted to localhost, rate limiting enabled`);
console.log(`🔑 OpenAI Key: ${OPENAI_API_KEY ? '✅' : '❌'} | ElevenLabs Key: ${ELEVENLABS_API_KEY ? '✅' : '❌'}`);
console.log(`📖 Pronunciations: ${pronunciationRules.length} rules loaded`);
