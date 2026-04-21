#!/data/data/com.termux/files/usr/bin/bash

OUT="idexncss.txt"

echo "📦 Dumping files into $OUT..."

echo "===== index.js =====" > $OUT
cat index.js >> $OUT

echo -e "\n\n===== public/index.html =====" >> $OUT
cat public/index.html >> $OUT

echo -e "\n\n===== public/css/styles.css =====" >> $OUT
cat public/css/styles.css >> $OUT

echo "✅ Done: $OUT created"
