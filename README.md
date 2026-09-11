# ROTA360 AKADEMİ V13

V12 altyapısı temel alınarak gerçek Supabase bağlantılı, Türkçe PWA ön yüzü ve koç/öğrenci akışları eklenmiş sürüm.

## İçerik
- Supabase Auth: öğrenci/koç kayıt-giriş-çıkış
- Otomatik öğrenci profili oluşturma
- Koç-öğrenci eşleştirme
- Haftalık program + günlük görevler
- Görev türleri: konu, soru, tekrar, deneme, YouTube
- YouTube ödevi URL, başlık ve süre
- Görev tamamlama ve koça otomatik bildirim
- Yeni görevde öğrenciye otomatik bildirim
- TYT/AYT deneme kayıtları ve net hesaplama
- AYT derslerini genişletmeye uygun JSONB alanı
- Konu analizi tablosu
- RLS güvenlik politikaları
- Bildirim merkezi
- Responsive mobil uyumlu PWA arayüz
- Türkçe kullanıcı arayüzü

## Kurulum
1. Supabase'de proje oluşturun.
2. `supabase/schema.sql` dosyasını SQL Editor'da tek seferde çalıştırın.
3. Bu pakette `src/config.js` Supabase Project URL ve **Publishable Key** ile doldurulmuştur.
4. Supabase Dashboard → SQL Editor bölümünde `supabase/schema.sql` dosyasını çalıştırın; ardından Auth ile kayıt olun. Service role key'i asla frontend'e koymayın.
5. `index.html`i statik hosting ile yayınlayın. HTTPS kullanın.
6. Öğrenci/koç hesaplarını uygulamadaki kayıt ekranından oluşturun.
7. Koç, Öğrenciler ekranından öğrenci UUID'si ile bağlantı kurabilir.
8. Koç Program Oluştur ekranından haftalık programı ve günlük görevleri ekler.
9. YouTube türündeki görevde video URL'si ve başlığı girilir.

## Güvenlik
RLS aktiftir. Frontend'de gizli service-role anahtarı bulunmaz. Üretimde e-posta doğrulaması, güçlü parola politikası ve Supabase Auth ayarları açılmalıdır.

## Not
Bu ZIP, Supabase hesabınızı veya hosting hesabınızı kendisi oluşturamaz. Gerçek bulut bağlantısı için `config.js` ve Supabase SQL kurulumu kullanıcıya aittir. V13 uygulama kodu bunun sonrasında doğrudan çalışacak şekilde hazırlanmıştır.


## Bu paket
Supabase Project URL ve Publishable Key kod tarafına bağlanmıştır. Yayına almadan önce RLS politikalarının ve Auth ayarlarının Supabase projesinde başarıyla uygulandığını kontrol edin.


## V13.1
Bu sürüm mevcut Supabase V13 veritabanı ile uyumludur. `profiles_coach_students` RLS politikası şemaya eklendi ve profil sorgusu oturum açmış kullanıcı ID'si ile sınırlandı. Frontend yalnızca Supabase Publishable Key kullanır; Secret/Service Role anahtarı kullanılmaz.
