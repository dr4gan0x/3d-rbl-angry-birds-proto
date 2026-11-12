# Varlık ve Lisans Kayıt Defteri

> **Kural:** Oyuna giren her dış varlık bu tabloya bir satır eklemek zorundadır.
> Satırı olmayan varlık oyuna girmez. Ayrıntılı politika:
> [tasarım spec'i](superpowers/specs/2026-11-12-flockfall-3d-slingshot-design.md) §1.

## Durum: tüm varlıklar prosedürel

Prototip **hiçbir dış varlık kullanmaz**. Her görsel öğe Roblox primitiflerinden
(`Part`, `WedgePart`, `CylinderPart`, `Ball`) kodla üretilir; hiçbir ses dosyası
yüklenmez. Bu nedenle aşağıdaki tablo **bilinçli olarak boştur**.

| id | tür | kaynak | lisans | doğrulama tarihi | ekleyen |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

## Üretilen görsel öğeler (lisans riski yok)

| Öğe | Nasıl üretilir | Dosya |
|---|---|---|
| Kuş gövdeleri | `Part` + `Shape = Ball`, düz renk | `src/server/FireService.luau` |
| Tinhead gövdesi | `Part` (küp) + `CorrodedMetal`, tek Neon göz | `src/server/BuildService.luau` |
| Yapı parçaları | `Part` + malzeme rengi (`BuildPlan.COLORS`) | `src/shared/core/BuildPlan.luau` |
| Patlayıcı varil | `Part` + `Shape = Cylinder` | `src/server/BuildService.luau` |
| Yörünge noktaları | 24 havuzlanmış `Part`, Neon | `src/client/TrajectoryPreview.luau` |
| Nişan işaretçisi | `Part`, Neon | `src/client/SlingshotController.luau` |
| Arayüz | `ScreenGui` + `Frame`/`TextLabel`/`TextButton` | `src/client/Hud.luau` |

## Yeni varlık ekleme kuralları

1. **Kendi üretimin** ise: kaynak = "prosedürel / ekip üretimi", lisans = "proje içi".
2. **Roblox resmî kütüphanesi** ise (yalnızca `creator = Roblox`): asset ID'yi
   yaz, lisans = "Roblox platform lisansı", doğrulama tarihini işle.
3. **Üçüncü taraf hiçbir varlık** (Creator Store modelleri, mesh'ler, dış müzik)
   lisans kaydı olmadan **eklenemez**. Şüphe varsa eklenmez.
4. Yasaklı kategoriler için spec §1.2 listesine bak. `node tools/verify-structure.mjs`
   yasaklı IP adlarını tarar ve ihlalde hata verir.
