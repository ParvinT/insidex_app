import os
import json
import re

def load_arb_keys(arb_path):
    """ARB dosyasındaki tüm keyleri yükle"""
    try:
        with open(arb_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        # @@ ile başlayan metadata'ları filtrele
        return {k: v for k, v in data.items() if not k.startswith('@@')}
    except Exception as e:
        print(f"❌ ARB dosyası okunamadı: {e}")
        return {}

def check_key_usage(key, search_dir):
    """Bir key'in lib/ klasöründe kullanılıp kullanılmadığını kontrol et"""
    patterns = [
        rf'\bl10n\.{key}\b',
        rf'\bAppLocalizations\.of\(context\)\.{key}\b'
    ]
    
    for root, dirs, files in os.walk(search_dir):
        # .dart dosyalarını kontrol et
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        for pattern in patterns:
                            if re.search(pattern, content):
                                return True, file_path
                except:
                    continue
    return False, None

def main():
    print("🔍 Kullanılmayan çeviri stringleri kontrol ediliyor...\n")
    
    arb_path = 'lib/l10n/app_en.arb'
    lib_path = 'lib/'
    
    # ARB dosyasını kontrol et
    if not os.path.exists(arb_path):
        print(f"❌ ARB dosyası bulunamadı: {arb_path}")
        return
    
    # ARB keylerini yükle
    arb_keys = load_arb_keys(arb_path)
    print(f"📊 Toplam {len(arb_keys)} adet çeviri stringi bulundu.\n")
    
    # Kullanılmayan keyleri bul
    unused_keys = []
    used_keys = []
    
    for key in arb_keys.keys():
        is_used, file_path = check_key_usage(key, lib_path)
        if is_used:
            used_keys.append(key)
            print(f"✅ {key}")
        else:
            unused_keys.append(key)
            print(f"❌ {key}")
    
    # Sonuçları göster
    print("\n" + "="*60)
    print(f"📈 Kullanılan: {len(used_keys)} adet")
    print(f"🗑️  Kullanılmayan: {len(unused_keys)} adet")
    print("="*60)
    
    if unused_keys:
        print("\n💡 Kullanılmayan stringler:")
        for key in unused_keys:
            print(f'  - {key}: "{arb_keys[key]}"')
        
        # Silme önerisi
        print("\n⚠️  Bu stringleri ARB dosyasından silmek ister misin?")
        print("   (Silmeden önce mutlaka yedek al!)")
    else:
        print("\n🎉 Harika! Tüm çeviri stringleri kullanılıyor!")

if __name__ == '__main__':
    main()