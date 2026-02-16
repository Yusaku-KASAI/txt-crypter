<template>
  <div :class="['app-wrapper', { 'is-decrypt-mode': isDecryptMode }]">
    <div v-if="!isDecryptMode" class="card encrypt-card">
      <h1 class="title">Secret Cipher Generator</h1>

      <div class="field">
        <label class="label">パスフレーズ</label>
        <input
          v-model="password"
          type="password"
          class="input-base"
          placeholder="鍵となるパスワード"
        />
      </div>

      <div class="field">
        <label class="label">暗号化するテキスト</label>
        <textarea
          v-model="mainText"
          class="textarea-base"
          placeholder="ここに秘密の情報を入力"
        ></textarea>
      </div>

      <div class="field">
        <label class="label">反復回数 (PBKDF2)</label>
        <input v-model.number="iterations" type="number" class="input-base small-input" />
      </div>

      <button @click="handleEncrypt" class="btn-red w-full py-12" :disabled="isProcessing">
        {{ isProcessing ? "生成中..." : "暗号化URLを生成" }}
      </button>

      <div v-if="generatedUrl" class="url-output mt-20">
        <label class="label">Notion埋め込み用URL</label>
        <div class="copy-row">
          <input :value="generatedUrl" readonly class="input-base url-field" />
          <button @click="copy(generatedUrl)" class="btn-gray px-15">コピー</button>
        </div>
      </div>
      <p v-if="errorMsg" class="error-text">{{ errorMsg }}</p>
    </div>

    <div v-else class="decrypt-container">
      <div v-if="decryptStep === 'locked'" class="locked-bar" @click="decryptStep = 'input'">
        <div class="dot-placeholder">••••••••</div>
        <div class="lock-btn-side">
          <svg
            viewBox="0 0 24 24"
            width="20"
            height="20"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
          >
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
          </svg>
        </div>
      </div>

      <div v-else-if="decryptStep === 'input'" class="input-ui-container">
        <div class="input-row-top">
          <div class="pass-input-box">
            <input
              v-model="password"
              :type="isPasswordVisible ? 'text' : 'password'"
              class="input-base main-input"
              placeholder="パスフレーズ"
              @keyup.enter="handleDecrypt"
              ref="passInput"
            />
            <button class="eye-btn" @click="isPasswordVisible = !isPasswordVisible">
              <svg
                v-if="!isPasswordVisible"
                viewBox="0 0 24 24"
                width="18"
                height="18"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
              >
                <path
                  d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"
                ></path>
                <line x1="1" y1="1" x2="23" y2="23"></line>
              </svg>
              <svg
                v-else
                viewBox="0 0 24 24"
                width="18"
                height="18"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
              >
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                <circle cx="12" cy="12" r="3"></circle>
              </svg>
            </button>
          </div>
          <div class="iter-input-box">
            <input v-model.number="iterations" type="number" class="input-base iter-input" />
          </div>
        </div>
        <div class="button-row-bottom">
          <button @click="decryptStep = 'locked'" class="btn-gray flex-1">✕ 閉じる</button>
          <button @click="handleDecrypt" class="btn-red flex-2" :disabled="isProcessing">
            復号
          </button>
        </div>
        <p v-if="errorMsg" class="error-text-mini">{{ errorMsg }}</p>
      </div>

      <div v-else-if="decryptStep === 'success'" class="success-ui-card">
        <div class="success-header">
          <button @click="copy(decryptedText)" class="btn-icon-outline" title="コピー">
            <svg
              viewBox="0 0 24 24"
              width="18"
              height="18"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
            >
              <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
              <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
            </svg>
          </button>
          <span class="timer-display">{{ timeLeft }}秒後に閉じられます。</span>
          <button @click="resetToLocked" class="btn-gray-sm">閉じる</button>
        </div>
        <div class="result-body">
          {{ decryptedText }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import CryptoJS from "crypto-js";

const password = ref("");
const iterations = ref(100000);
const mainText = ref("");
const decryptedText = ref("");
const generatedUrl = ref("");
const errorMsg = ref("");
const saltHex = ref("");
const ivHex = ref("");
const encryptedPayload = ref("");

const isDecryptMode = ref(false);
const decryptStep = ref("locked");
const isPasswordVisible = ref(false);
const isProcessing = ref(false);
const timeLeft = ref(30);
let timerInterval = null;

onMounted(() => {
  const params = new URLSearchParams(window.location.search);
  const txt = params.get("txt");
  const s = params.get("s");
  const iter = params.get("iter");
  const iv = params.get("iv");

  if (txt && s && iv) {
    isDecryptMode.value = true;
    encryptedPayload.value = txt;
    saltHex.value = s;
    ivHex.value = iv;
    if (iter) iterations.value = parseInt(iter);
  }
});

const handleEncrypt = () => {
  if (!password.value || !mainText.value) return;
  isProcessing.value = true;
  setTimeout(() => {
    try {
      const salt = CryptoJS.lib.WordArray.random(128 / 8);
      const iv = CryptoJS.lib.WordArray.random(128 / 8);
      const key = CryptoJS.PBKDF2(password.value, salt, {
        keySize: 256 / 32,
        iterations: iterations.value,
      });
      const encrypted = CryptoJS.AES.encrypt(mainText.value, key, { iv: iv }).toString();
      const baseUrl = window.location.origin + window.location.pathname;
      generatedUrl.value = `${baseUrl}?txt=${encodeURIComponent(encrypted)}&s=${salt.toString()}&iv=${iv.toString()}&iter=${iterations.value}`;
    } catch (e) {
      errorMsg.value = "暗号化失敗";
    }
    isProcessing.value = false;
  }, 50);
};

const handleDecrypt = () => {
  if (!password.value || !encryptedPayload.value || !ivHex.value) return;
  isProcessing.value = true;
  errorMsg.value = "";
  setTimeout(() => {
    try {
      const salt = CryptoJS.enc.Hex.parse(saltHex.value);
      const iv = CryptoJS.enc.Hex.parse(ivHex.value);
      const key = CryptoJS.PBKDF2(password.value, salt, {
        keySize: 256 / 32,
        iterations: iterations.value,
      });
      const bytes = CryptoJS.AES.decrypt(encryptedPayload.value, key, { iv: iv });
      const decrypted = bytes.toString(CryptoJS.enc.Utf8);
      if (!decrypted) throw new Error();
      decryptedText.value = decrypted;
      decryptStep.value = "success";
      startTimer();
    } catch (e) {
      errorMsg.value = "パスフレーズが違います";
    }
    isProcessing.value = false;
  }, 50);
};

const startTimer = () => {
  timeLeft.value = 30;
  clearInterval(timerInterval);
  timerInterval = setInterval(() => {
    timeLeft.value--;
    if (timeLeft.value <= 0) resetToLocked();
  }, 1000);
};

const resetToLocked = () => {
  clearInterval(timerInterval);
  decryptStep.value = "locked";
  decryptedText.value = "";
  password.value = "";
  errorMsg.value = "";
};

/**
 * 修正版コピー関数
 * Notion等のiframe環境向けにFallback処理を追加
 */
const copy = async (t) => {
  try {
    // 1. まずモダンなAPIを試行
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(t);
    } else {
      throw new Error("Clipboard API unavailable");
    }
  } catch (err) {
    // 2. 失敗した場合、古い方式（textarea生成）を実行
    const textArea = document.createElement("textarea");
    textArea.value = t;
    textArea.style.position = "fixed";
    textArea.style.left = "-9999px";
    textArea.style.top = "0";
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
      document.execCommand("copy");
    } catch (copyErr) {
      console.error("Copy failed", copyErr);
    }
    document.body.removeChild(textArea);
  }
  alert("コピーしました");
};
</script>

<style scoped>
/* スタイルは変更なしのため省略（前のコードのものをそのまま使用してください） */
.app-wrapper {
  font-family: -apple-system, sans-serif;
  display: flex;
  justify-content: center;
  background: transparent;
}
.is-decrypt-mode {
  padding: 0;
}
.input-base {
  border: 1px solid #ced4da;
  border-radius: 4px;
  padding: 8px 12px;
  font-size: 16px;
  outline: none;
  width: 100%;
  box-sizing: border-box;
}
.btn-red {
  background: #d9534f;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
  display: flex;
  align-items: center;
  justify-content: center;
}
.btn-gray {
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.label {
  display: block;
  font-size: 12px;
  font-weight: bold;
  color: #495057;
  margin-bottom: 5px;
}
.encrypt-card {
  width: 100%;
  max-width: 500px;
  background: #fff;
  padding: 25px;
  border: 1px solid #ddd;
  border-radius: 8px;
  margin-top: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}
.textarea-base {
  width: 100%;
  height: 100px;
  border: 1px solid #ced4da;
  border-radius: 4px;
  padding: 8px;
  font-size: 14px;
  resize: none;
  margin-bottom: 15px;
}
.small-input {
  width: 150px;
}
.url-output {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 6px;
  border: 1px dashed #ccc;
}
.copy-row {
  display: flex;
  gap: 8px;
}
.decrypt-container {
  width: 100%;
}
.locked-bar {
  display: flex;
  align-items: center;
  width: 100%;
  border: 1px solid #dee2e6;
  border-radius: 6px;
  background: #fff;
  overflow: hidden;
  cursor: pointer;
}
.dot-placeholder {
  flex: 1;
  padding: 10px 15px;
  line-height: 20px;
  color: #adb5bd;
  font-size: 18px;
  letter-spacing: 2px;
}
.lock-btn-side {
  background: #6c757d;
  color: white;
  padding: 10px 15px;
  display: flex;
  align-items: center;
}
.input-ui-container {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.input-row-top {
  display: flex;
  gap: 8px;
}
.pass-input-box {
  flex: 3;
  position: relative;
}
.iter-input-box {
  flex: 1;
}
.main-input {
  padding-right: 40px;
}
.eye-btn {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  cursor: pointer;
  color: #adb5bd;
  padding: 0;
  display: flex;
}
.iter-input {
  text-align: center;
  color: #495057;
}
.button-row-bottom {
  display: flex;
  gap: 8px;
}
.button-row-bottom button {
  padding: 10px;
  font-size: 15px;
}
.success-ui-card {
  width: 100%;
  border: 1px solid #dee2e6;
  border-radius: 6px;
  background: #fff;
  overflow: hidden;
}
.success-header {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  border-bottom: 1px solid #f1f3f5;
  background: #fdfdfd;
}
.btn-icon-outline {
  border: 1px solid #ced4da;
  background: white;
  border-radius: 4px;
  padding: 6px;
  cursor: pointer;
  color: #666;
  display: flex;
  margin-right: 15px;
}
.timer-display {
  flex: 1;
  font-size: 13px;
  color: #666;
}
.btn-gray-sm {
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 5px 12px;
  cursor: pointer;
  font-size: 13px;
  font-weight: bold;
}
.result-body {
  padding: 15px;
  font-size: 16px;
  font-family: "Courier New", Courier, monospace;
  color: #212529;
  word-break: break-all;
}
.w-full {
  width: 100%;
}
.flex-1 {
  flex: 1;
}
.flex-2 {
  flex: 2;
}
.py-12 {
  padding-top: 12px;
  padding-bottom: 12px;
}
.px-15 {
  padding-left: 15px;
  padding-right: 15px;
}
.mt-20 {
  margin-top: 20px;
}
.error-text {
  color: #d9534f;
  font-size: 14px;
  text-align: center;
  margin-top: 10px;
}
.error-text-mini {
  color: #d9534f;
  font-size: 12px;
  margin-top: 4px;
  font-weight: bold;
}
</style>
