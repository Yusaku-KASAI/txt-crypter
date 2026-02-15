<template>
  <div class="container">
    <h1>Self-Hosted Text Cipher</h1>

    <div class="input-group">
      <label>マスターパスワード (共通鍵):</label>
      <input v-model="masterKey" type="password" placeholder="暗号化・復号化に使う鍵を入力" />
    </div>

    <div class="input-group">
      <label>入力テキスト:</label>
      <textarea
        v-model="inputText"
        placeholder="ここに暗号化したい文字列、または復号したい暗号文を入力"
      ></textarea>
    </div>

    <div class="actions">
      <button @click="encrypt" class="btn-encrypt">暗号化 ↓</button>
      <button @click="decrypt" class="btn-decrypt">復号化 ↑</button>
    </div>

    <div class="input-group">
      <label>結果:</label>
      <textarea v-model="outputText" readonly placeholder="結果がここに表示されます"></textarea>
      <button v-if="outputText" @click="copyToClipboard" class="btn-copy">結果をコピー</button>
    </div>

    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <div class="footer">
      <p>※このツールはブラウザ内でのみ処理を行い、サーバーへデータを送信しません。</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import CryptoJS from "crypto-js";

const masterKey = ref("");
const inputText = ref("");
const outputText = ref("");
const errorMessage = ref("");

// 暗号化処理
const encrypt = () => {
  if (!masterKey.value || !inputText.value) {
    errorMessage.value = "パスワードとテキストを入力してください。";
    return;
  }
  try {
    const encrypted = CryptoJS.AES.encrypt(inputText.value, masterKey.value).toString();
    outputText.value = encrypted;
    errorMessage.value = "";
  } catch (e) {
    errorMessage.value = "暗号化に失敗しました。";
  }
};

// 復号化処理
const decrypt = () => {
  if (!masterKey.value || !inputText.value) {
    errorMessage.value = "パスワードとテキストを入力してください。";
    return;
  }
  try {
    const bytes = CryptoJS.AES.decrypt(inputText.value, masterKey.value);
    const decrypted = bytes.toString(CryptoJS.enc.Utf8);

    if (!decrypted) {
      throw new Error("Invalid key");
    }

    outputText.value = decrypted;
    errorMessage.value = "";
  } catch (e) {
    errorMessage.value = "復号に失敗しました。パスワードが正しくないか、データが壊れています。";
    outputText.value = "";
  }
};

// コピー機能
const copyToClipboard = () => {
  navigator.clipboard.writeText(outputText.value);
  alert("コピーしました");
};
</script>

<style scoped>
.container {
  max-width: 600px;
  margin: 20px auto;
  padding: 20px;
  font-family: sans-serif;
  background: #f9f9f9;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.input-group {
  margin-bottom: 20px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

input[type="password"],
textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  box-sizing: border-box;
}

textarea {
  height: 120px;
  resize: vertical;
}

.actions {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

button {
  flex: 1;
  padding: 10px;
  cursor: pointer;
  border: none;
  border-radius: 4px;
  color: white;
  font-weight: bold;
}

.btn-encrypt {
  background-color: #42b983;
}
.btn-decrypt {
  background-color: #35495e;
}
.btn-copy {
  background-color: #eee;
  color: #333;
  margin-top: 5px;
  width: auto;
}

.error {
  color: red;
  font-size: 0.9em;
}
.footer {
  margin-top: 30px;
  font-size: 0.8em;
  color: #666;
  text-align: center;
}
</style>
