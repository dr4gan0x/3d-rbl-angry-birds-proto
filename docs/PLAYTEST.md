# Oynanış Test Kontrol Listesi (Roblox Studio)

Otomatik testler yalnızca saf mantığı kapsar. Aşağıdaki maddeler Studio'da
**elle** doğrulanmalıdır; her madde "geçti" veya "kaldı" olarak işaretlenir.

## Kurulum

```
rojo serve
# Studio: Baseplate > Rojo eklentisi > Connect > Play (F5)
```

## 1. Girdi

- [ ] **Fare ile nişan:** Sapan üzerinde sol tık + sürükle; kuş işaretçiyi takip ediyor.
- [ ] **Fare ile fırlatma:** Bırakınca `FireRequest` gidiyor, kuş uçuyor.
- [ ] **Dokunma ile nişan:** Telefon emülatöründe tek parmakla sürükleme çalışıyor.
- [ ] **Gamepad:** A tuşu basılı tut + yön; nişan alınıyor.
- [ ] **Kamera:** Sağ tık + sürükle kamera yörüngesini döndürüyor.
- [ ] **Ölü bölge:** Çok hafif dokunma (0.5 stud) atış başlatmıyor.
- [ ] **Zayıf atış:** 0.9 stud çekme atış iptal ediyor, kuş kaybedilmiyor.

## 2. Fizik ve yörünge

- [ ] **Önizleme doğruluğu:** Gösterilen noktalar kuşun gerçek uçuşuyla örtüşüyor (±~2 stud).
- [ ] **Yay şekli:** Yörünge parabol; tepe noktası önizlemede görünüyor.
- [ ] **Menzil:** 260 stud/s tam güçte ~340 stud ileri gidiyor.
- [ ] **Yan atış:** Yandan çekip çapraz atış yapılabiliyor.

## 3. Yıkım

- [ ] **Glass kolay kırılıyor:** Tek isabetle cam parça yok oluyor.
- [ ] **Wood dayanıyor:** Tek isabetle kırılmıyor, ikincide gidiyor.
- [ ] **Stone zor:** 2–3 isabet gerekiyor.
- [ ] **Metal kırılmıyor:** Ne kadar vurursan vur, ayakta kalıyor.
- [ ] **Enkaz temizliği:** Kırılan parça ~2.5 sn sonra yok oluyor.
- [ ] **Kendi kendine çökme yok:** Seviyeyi yükle, hiç atış yapma, 10 sn bekle — yapı ayakta.

## 4. Kuşlar

- [ ] **Wren:** Yetenek yok, Space bir şey yapmıyor.
- [ ] **Swallow:** Uçuşta Space hızı belirgin artırıyor.
- [ ] **Puffin:** Uçuşta Space patlama yaratıyor, çevredeki parçalar savruluyor.
- [ ] **Yetenek tek kullanım:** İkinci Space yok sayılıyor.

## 5. Tur akışı

- [ ] **Skor artıyor:** Tinhead ölünce +500, kırılan parça +40/+90.
- [ ] **Kazanma:** Tüm Tinhead'ler ölünce "SONRAKI" paneli açılıyor.
- [ ] **Kaybetme:** Kuşler bitince ve Tinhead kalınca "TEKRAR" paneli açılıyor.
- [ ] **Son kuş = kazanma:** Son kuşla son Tinhead ölürse kazanma sayılıyor.
- [ ] **Settling:** Kuş durunca tur otomatik ilerliyor (4 sn takılmıyor).
- [ ] **Kuş sayacı:** HUD'daki sayı her atışta 1 azalıyor.

## 6. Seviyeler

- [ ] **Level 1 yükleniyor:** 5 parça, 2 Tinhead görünüyor.
- [ ] **Level 2:** Metal kiriş ve patlayıcı varil görünüyor.
- [ ] **Level 3:** 8 parça, 5 Tinhead, 2 varil.
- [ ] **Varil patlaması:** Varile yüksek hızla vurunca patlıyor, çevre hasar alıyor.

## 7. Arayüz

- [ ] **Mobil okunabilirlik:** Telefon emülatöründe (örn. iPhone 14) tüm yazılar okunuyor.
- [ ] **Dokunma hedefi:** Sonuç paneli düğmeleri rahatça basılıyor.
- [ ] **Yatay/dikey:** Ekran yönü değişince HUD bozulmuyor.

## 8. Performans

- [ ] **FPS:** Orta seviye cihaz emülasyonunda 30+ FPS.
- [ ] **Parça sayısı:** Çalışma anında Workspace'te < 100 parça.
- [ ] **Çıktı temiz:** Studio Output'ta kırmızı hata yok.

## Bulgular

| # | Madde | Durum | Not |
|---|---|---|---|
| | | | |
