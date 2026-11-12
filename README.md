# Flockfall — 3D Sapan Fizik Prototipi (Roblox)

Roblox için 3D sapan fizik oyunu prototipi. Kuşları sapanla fırlat, **Tinhead**
nöbetçilerini devir, yıkılabilir yapıları çökert.

> **Özgün IP.** Bu proje hiçbir ticari markanın, karakterin, sesin veya
> seviyesinin lisanslı varlığını kullanmaz. Tüm görseller ve sesler kodla
> üretilir. Ayrıntılar: [docs/ASSETS.md](docs/ASSETS.md).

---

## Ne var?

| Katman | İçerik |
|---|---|
| Oyun mantığı (saf Luau, test edilir) | Yörünge fiziği, 3D nişan modeli, hasar/yıkım, skor, seviye şeması, tur durum makinesi |
| Sunucu (yetkili) | Atış doğrulama, fizik, hasar uygulama, seviye yaşam döngüsü |
| İstemci | Sapan girdisi (fare/dokunma/gamepad), kamera, yörünge önizlemesi, HUD |
| İçerik | 3 el yapımı seviye, 3 kuş tipi, 4 malzeme, 5 Tinhead |

## Gereksinimler

- **Node.js 22+** (test koşucusu için)
- **Roblox Studio** (oyunu çalıştırmak için)
- **Rojo 7.x** eklentisi + CLI ([rojo-rbx/rojo](https://github.com/rojo-rbx/rojo))

## Kurulum

```bash
npm install
```

## Testler

```bash
npm test                 # tüm saf mantık testleri
npm test -- AimModel     # tek modül
node tools/verify-structure.mjs   # katman + IP kuralları
node tools/syntax-check.mjs       # tüm .luau dosyaları derleniyor mu
```

Testler gerçek bir **Luau 0.739** sanal makinesinde (WASM) koşar — Roblox
Studio gerekmez. Kapsam: yörünge, nişan, hasar, skor, seviye doğrulama, tur
durum makinesi, rate limiting, hasar kuyruğu.

## Studio'da çalıştırma

```bash
rojo serve
```

1. Roblox Studio'da boş bir **Baseplate** aç.
2. Rojo eklentisinden `localhost:34872`'ye bağlan.
3. **Play** (F5).

`default.project.json` şunları eşler:

| Dosya | Roblox |
|---|---|
| `src/shared/` | `ReplicatedStorage.Shared` |
| `src/server/` | `ServerScriptService.Server` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` |

## Kontroller

| Eylem | Fare | Dokunma | Gamepad |
|---|---|---|---|
| Nişan al / fırlat | Sapanı çek, bırak (sol tık) | Sürükle, bırak | A basılı tut, bırak |
| Kamerayı döndür | Sağ tık + sürükle | — | — |
| Kuş yeteneği (uçuşta) | `Space` | İkinci parmak | — |

**Nişan mantığı:** yatay çekme yönü belirler, dikey çekme açıyı, mesafe gücü.
Sapanın etrafında 8 stud'luk bir daire çekilebilir.

## Seviyeler

| # | Ad | Kuş | Tinhead | Öne çıkan |
|---|---|---|---|---|
| 1 | Kırık Avlu | 3 × Wren | 2 | Öğretici, açık cephe |
| 2 | Vincin Altında | Wren, Wren, Swallow, Puffin | 3 | Metal kiriş, patlayıcı varil |
| 3 | Tinhead Kalesi | 5 kuş | 5 | Metal iskelet, 2 varil, zincirleme |

## Kuşlar

| Kuş | Kütle | Yetenek |
|---|---|---|
| **Wren** | 2.0 | — |
| **Swallow** | 1.2 | Uçuşta 1.9× hız patlaması |
| **Puffin** | 3.5 | 0.4 sn sonra patlama (14 stud) |

## Malzemeler

| Malzeme | HP | Not |
|---|---|---|
| Wood | 55 | Standart |
| Glass | 24 | Kolay kırılır |
| Stone | 140 | Ağır |
| **Metal** | ∞ | **Kırılmaz** — tasarım aracı |

## Proje yapısı

```
src/
├── shared/
│   ├── core/          # SAF Luau — Roblox API'si yok, %100 test edilir
│   ├── config/        # GameConfig, Materials (enjekte edilir)
│   ├── levels/        # 3 seviye + register
│   ├── testkit/       # Studio içi test API'si
│   └── Remotes.luau
├── server/            # Yetkili fizik, hasar, tur akışı
└── client/            # Girdi, kamera, HUD
tests/                 # *.spec.luau — CI'da çalışır
tools/                 # test koşucusu, yapı doğrulayıcı
docs/
├── ASSETS.md          # varlık ve lisans kayıt defteri
├── PLAYTEST.md        # Studio elle test kontrol listesi
└── superpowers/       # tasarım spec'i + uygulama planı
```

**Katman kuralı:** `src/shared/core/` içinde `game`, `workspace`, `Instance`,
`Vector3`, `script`, `task` **kullanılmaz**. Bu dosyalar Roblox olmadan koşar.
Konfigürasyon parametre olarak geçer (dependency injection).

## Tasarım dokümanları

- [Tasarım spec'i](docs/superpowers/specs/2026-11-12-flockfall-3d-slingshot-design.md)
- [Uygulama planı](docs/superpowers/plans/2026-11-12-flockfall-mvp.md)
- [Oynanış test listesi](docs/PLAYTEST.md)
