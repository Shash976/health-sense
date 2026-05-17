// comms.ino — Low-level HTTP helpers used by route handlers.

void respondJSON(WiFiClient& client, const String& json, int code = 200) {
  client.println("HTTP/1.1 " + String(code) + " OK");
  client.println("Content-Type: application/json");
  client.println("Access-Control-Allow-Origin: *");
  client.println("Connection: close");
  client.println();
  client.println(json);
  Serial.print("Sent: "); Serial.println(json);
}

int getContentLength(WiFiClient& client) {
  int contentLength = 0;
  while (client.available()) {
    String line = client.readStringUntil('\n');
    line.trim();
    if (line.length() == 0) break;
    line.toLowerCase();
    if (line.startsWith("content-length:")) {
      contentLength = line.substring(line.indexOf(':') + 1).toInt();
    }
  }
  return contentLength;
}

String readRequestBody(WiFiClient& client, int length) {
  uint8_t buffer[256];
  int read = client.readBytes(buffer, length);
  return String((char*)buffer).substring(0, read);
}
