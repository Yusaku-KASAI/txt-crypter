<template>
  <div :class="['app-wrapper', { 'simple-mode': isDecryptMode }]">
    <div class="card">
      <div v-if="!decryptedText">
        <h1 v-if="!isDecryptMode" class="title">Secret Cipher Pro</h1>

        <div class="field">
          <div class="input-with-icon">
            <input
              v-model="password"
              :type="isPasswordVisible ? 'text' : 'password'"
              placeholder="パスワード"
              class="input-minimal"
              @keyup.enter="executeAction"
            />
            <button @click="isPasswordVisible = !isPasswordVisible" class="icon-btn" type="button">
              <svg
                v-if="isPasswordVisible"
                xmlns="http://www.w3.org/2000/svg"
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path
                  d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"
                ></path>
                <line x1="1" y1="1" x2="23" y2="23"></line>
              </svg>
              <svg
                v-else
                xmlns="http://www.w3.org/2000/svg"
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                <circle cx="12" cy="12" r="3"></circle>
              </svg>
            </button>
          </div>
        </div>

        <div v-if="!isDecryptMode" class="field mt-10">
          <textarea
            v-model="mainText"
            placeholder="暗号化したいテキスト"
            class="textarea-minimal"
          ></textarea>
        </div>

        <details class="advanced-settings">
          <summary>セキュリティ設定 (Iterations: {{ iterations.toLocaleString() }})</summary>
          <div class="mt-5">
            <label class="small-label">反復回数:</label>
            <input
              v-model.number="iterations"
              type="number"
              step="10000"
              class="input-minimal small"
            />
          </div>
        </details>

        <button @click="executeAction" class="btn-main mt-10" :disabled="isProcessing">
          {{ isProcessing ? "処理中..." : isDecryptMode ? "復号する" : "暗号化URLを生成" }}
        </button>

        <div v-if="!isDecryptMode && generatedUrl" class="url-box mt-10">
          <div class="copy-group">
            <input type="text" :value="generatedUrl" readonly class="input-minimal small-text" />
            <button @click="copy(generatedUrl)" class="btn-copy-small">URLコピー</button>
          </div>
        </div>
      </div>

      <div v-else class="success-screen">
        <div class="field">
          <div class="input-with-icon">
            <textarea
              v-model="decryptedText"
              readonly
              :class="['textarea-minimal result-display', { masked: !isResultVisible }]"
            ></textarea>
            <button
              @click="isResultVisible = !isResultVisible"
              class="icon-btn top-right"
              type="button"
            >
              <svg
                v-if="isResultVisible"
                xmlns="http://www.w3.org/2000/svg"
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                <circle cx="12" cy="12" r="3"></circle>
              </svg>
              <svg
                v-else
                xmlns="http://www.w3.org/2000/svg"
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path
                  d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"
                ></path>
                <line x1="1" y1="1" x2="23" y2="23"></line>
              </svg>
            </button>
          </div>
        </div>
        <button @click="copy(decryptedText)" class="btn-copy-big">コピーする</button>
        <button @click="reset" class="btn-reset">パスワード入力に戻る</button>
      </div>

      <p v-if="errorMsg" class="error-text">{{ errorMsg }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import CryptoJS from "crypto-js";

const password = ref("");
const iterations = ref(100000);
const mainText = ref("");
const encryptedPayload = ref("");
const saltHex = ref("");
const decryptedText = ref("");
const generatedUrl = ref("");
const errorMsg = ref("");

const isDecryptMode = ref(false);
const isPasswordVisible = ref(false);
const isResultVisible = ref(false);
const isProcessing = ref(false);

onMounted(() => {
  const params = new URLSearchParams(window.location.search);
  const txt = params.get("txt");
  const iter = params.get("iter");
  const s = params.get("s"); // Salt

  if (txt && s) {
    isDecryptMode.value = true;
    encryptedPayload.value = txt;
    saltHex.value = s;
    if (iter) iterations.value = parseInt(iter);
  }
});

const executeAction = () => {
  isDecryptMode.value ? handleDecrypt() : handleEncrypt();
};

// 鍵生成 (PBKDF2) - 非同期を擬似的に扱えるように
const deriveKey = (pass, salt, iter) => {
  return CryptoJS.PBKDF2(pass, salt, { keySize: 256 / 32, iterations: iter });
};

const handleEncrypt = () => {
  if (!password.value || !mainText.value) return;
  isProcessing.value = true;

  // 100ms待機してUIの更新（「処理中...」表示）を優先させる
  setTimeout(() => {
    try {
      // 1. ランダムな128bitソルトを生成
      const salt = CryptoJS.lib.WordArray.random(128 / 8);
      // 2. 鍵を生成
      const key = deriveKey(password.value, salt, iterations.value);
      // 3. 固定IVでAES暗号化
      const iv = CryptoJS.enc.Hex.parse("00000000000000000000000000000000");
      const encrypted = CryptoJS.AES.encrypt(mainText.value, key, { iv: iv }).toString();

      const baseUrl = window.location.origin + window.location.pathname;
      // 4. 暗号文、ソルト(Hex)、反復回数をURLに含める
      generatedUrl.value = `${baseUrl}?txt=${encodeURIComponent(encrypted)}&s=${salt.toString()}&iter=${iterations.value}`;
      errorMsg.value = "";
    } catch (e) {
      errorMsg.value = "暗号化失敗";
    } finally {
      isProcessing.value = false;
    }
  }, 100);
};

const handleDecrypt = () => {
  if (!password.value || !encryptedPayload.value || !saltHex.value) return;
  isProcessing.value = true;

  setTimeout(() => {
    try {
      // 1. URLから取得したHex文字列をWordArrayに戻す
      const salt = CryptoJS.enc.Hex.parse(saltHex.value);
      const key = deriveKey(password.value, salt, iterations.value);
      const iv = CryptoJS.enc.Hex.parse("00000000000000000000000000000000");

      const bytes = CryptoJS.AES.decrypt(encryptedPayload.value, key, { iv: iv });
      const decrypted = bytes.toString(CryptoJS.enc.Utf8);

      if (!decrypted) throw new Error();

      decryptedText.value = decrypted;
      isResultVisible.value = true;
      errorMsg.value = "";
    } catch (e) {
      errorMsg.value = "パスワードが違います";
      decryptedText.value = "";
    } finally {
      isProcessing.value = false;
    }
  }, 100);
};

const reset = () => {
  decryptedText.value = "";
  password.value = "";
};

const copy = async (text) => {
  await navigator.clipboard.writeText(text);
  alert("コピーしました");
};
</script>

<style scoped>
/* スタイルは前回の「シンプルかつNotion親和」を継承し、さらに調整 */
.app-wrapper {
  display: flex;
  justify-content: center;
  background: transparent;
  font-family: -apple-system, sans-serif;
}
.card {
  width: 100%;
  max-width: 400px;
  padding: 5px;
}
.title {
  font-size: 1rem;
  margin: 0 0 15px;
  text-align: center;
  color: #333;
}

.input-with-icon {
  position: relative;
  display: flex;
  align-items: center;
}
.input-minimal,
.textarea-minimal {
  width: 100%;
  padding: 10px 35px 10px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  outline: none;
  box-sizing: border-box;
  background: #fff;
}
.textarea-minimal {
  height: 80px;
  resize: none;
  border-color: #eee;
}

.result-display {
  height: 100px;
  font-size: 15px;
  background: #fdfdfd;
  font-family: monospace;
  border: 2px solid #2383e2;
}
.result-display.masked {
  color: transparent;
  text-shadow: 0 0 10px rgba(0, 0, 0, 0.4);
  user-select: none;
  border: 1px solid #eee;
}

.icon-btn {
  position: absolute;
  right: 10px;
  background: none;
  border: none;
  cursor: pointer;
  color: #ccc;
  padding: 0;
}
.icon-btn.top-right {
  top: 10px;
}

.btn-main {
  width: 100%;
  padding: 12px;
  background: #000;
  color: #fff;
  border: none;
  border-radius: 6px;
  font-weight: bold;
  cursor: pointer;
}
.btn-main:disabled {
  background: #666;
  cursor: not-allowed;
}

.btn-copy-big {
  width: 100%;
  margin-top: 10px;
  padding: 14px;
  background: #2383e2;
  color: white;
  border: none;
  border-radius: 6px;
  font-weight: bold;
  cursor: pointer;
  font-size: 15px;
}
.btn-reset {
  width: 100%;
  margin-top: 8px;
  padding: 8px;
  background: transparent;
  color: #999;
  border: none;
  cursor: pointer;
  font-size: 12px;
}

.advanced-settings {
  font-size: 11px;
  color: #bbb;
  margin-top: 10px;
}
.advanced-settings summary {
  cursor: pointer;
}
.small-label {
  display: block;
  margin-bottom: 2px;
}
.input-minimal.small {
  width: 110px;
  padding: 4px 8px;
  font-size: 11px;
}

.copy-group {
  display: flex;
  gap: 8px;
}
.small-text {
  font-size: 11px;
  color: #999;
  overflow: hidden;
  text-overflow: ellipsis;
}
.mt-10 {
  margin-top: 10px;
}
.error-text {
  color: #eb5757;
  font-size: 12px;
  text-align: center;
  margin-top: 10px;
}
</style>
