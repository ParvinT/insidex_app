# l10n_cleanup_suite.py

import os
import json
import re
import shutil
from datetime import datetime
from pathlib import Path

class L10nCleanupTool:
    def __init__(self):
        self.arb_files = {
            'en': 'lib/l10n/app_en.arb',
            'tr': 'lib/l10n/app_tr.arb',
            'ru': 'lib/l10n/app_ru.arb',
            'hi': 'lib/l10n/app_hi.arb',
        }
        self.lib_path = 'lib/'
        self.master_file = 'lib/l10n/app_en.arb'
        
        # Results storage
        self.all_keys = {}
        self.usage_data = {}
        self.backup_created = False
        
    # =================== STAGE 1: ANALYSIS ===================
    
    def load_all_arb_files(self):
        """Tüm ARB dosyalarını yükle"""
        print("📂 Loading ARB files...")
        
        for lang, path in self.arb_files.items():
            if os.path.exists(path):
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    # @ ile başlayan metadata'ları filtrele
                    self.all_keys[lang] = {
                        k: v for k, v in data.items() 
                        if not k.startswith('@@')
                    }
                    print(f"   ✅ {lang}: {len(self.all_keys[lang])} keys")
                except Exception as e:
                    print(f"   ❌ {lang}: Error - {e}")
            else:
                print(f"   ⚠️  {lang}: File not found")
    
    def analyze_key_usage(self, key):
        """Bir key'in detaylı kullanım analizini yap"""
        patterns = [
            # Standard usage patterns
            rf'\bl10n\.{key}\b',
            rf'\bAppLocalizations\.of\(context\)\.{key}\b',
            
            # Extension usage
            rf'\bcontext\.l10n\.{key}\b',
            
            # Bracket notation (dynamic access)
            rf"l10n\['{key}'\]",
            rf'l10n\["{key}"\]',
            
            # String references (might be used in configs)
            rf"'{key}':\s*",
            rf'"{key}":\s*',
            
            # Comment usage (might be planned feature)
            rf'//.*\bl10n\.{key}\b',
            rf'/\*.*\bl10n\.{key}\b.*\*/',
        ]
        
        locations = []
        comment_only = True
        
        for root, dirs, files in os.walk(self.lib_path):
            # Skip generated and tool files
            if any(skip in root for skip in ['.dart_tool', 'generated', '.g.dart']):
                continue
            
            for file in files:
                if not file.endswith('.dart'):
                    continue
                
                file_path = os.path.join(root, file)
                
                # Skip auto-generated l10n files
                if 'app_localizations' in file_path:
                    continue
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        lines = content.split('\n')
                    
                    for i, line in enumerate(lines, 1):
                        for pattern in patterns:
                            if re.search(pattern, line):
                                is_comment = '//' in line or '/*' in line or '*/' in line
                                if not is_comment:
                                    comment_only = False
                                
                                locations.append({
                                    'file': file_path,
                                    'line': i,
                                    'content': line.strip(),
                                    'is_comment': is_comment
                                })
                except:
                    continue
        
        # Kategorize et
        if not locations:
            return 'UNUSED', []
        elif comment_only:
            return 'COMMENT_ONLY', locations
        else:
            return 'USED', locations
    
    def perform_deep_analysis(self):
        """Tüm key'lerin detaylı analizini yap"""
        print("\n🔬 Performing deep analysis...")
        print("=" * 80)
        
        # EN (master) dosyasını baz al
        if 'en' not in self.all_keys:
            print("❌ Master file (EN) not found!")
            return
        
        master_keys = self.all_keys['en']
        total = len(master_keys)
        
        for idx, (key, value) in enumerate(master_keys.items(), 1):
            print(f"\rAnalyzing... {idx}/{total} ({(idx/total)*100:.1f}%)", end='')
            
            status, locations = self.analyze_key_usage(key)
            
            self.usage_data[key] = {
                'value': value,
                'status': status,
                'locations': locations,
                'translations': {
                    lang: self.all_keys[lang].get(key, 'MISSING')
                    for lang in ['tr', 'ru', 'hi']
                }
            }
        
        print("\n✅ Analysis complete!")
    
    def generate_detailed_report(self):
        """Detaylı rapor oluştur"""
        print("\n📊 Generating detailed report...")
        
        # Kategorilere ayır
        unused = {k: v for k, v in self.usage_data.items() if v['status'] == 'UNUSED'}
        comment_only = {k: v for k, v in self.usage_data.items() if v['status'] == 'COMMENT_ONLY'}
        used = {k: v for k, v in self.usage_data.items() if v['status'] == 'USED'}
        
        # Console report
        print("=" * 80)
        print(f"📈 SUMMARY:")
        print(f"   ✅ Used: {len(used)} keys")
        print(f"   ⚠️  Comment Only: {len(comment_only)} keys")
        print(f"   ❌ Unused: {len(unused)} keys")
        print("=" * 80)
        
        # Detailed file report
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = f'l10n_analysis_{timestamp}.txt'
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write("=" * 80 + "\n")
            f.write("L10N CLEANUP ANALYSIS REPORT\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 80 + "\n\n")
            
            # UNUSED section
            f.write(f"❌ UNUSED KEYS ({len(unused)}):\n")
            f.write("-" * 80 + "\n")
            for key, data in sorted(unused.items()):
                f.write(f"\n🔑 {key}\n")
                f.write(f"   EN: \"{data['value']}\"\n")
                for lang, trans in data['translations'].items():
                    if trans != 'MISSING':
                        f.write(f"   {lang.upper()}: \"{trans}\"\n")
            
            # COMMENT ONLY section
            f.write(f"\n\n⚠️  COMMENT ONLY ({len(comment_only)}):\n")
            f.write("-" * 80 + "\n")
            for key, data in sorted(comment_only.items()):
                f.write(f"\n🔑 {key}\n")
                f.write(f"   Value: \"{data['value']}\"\n")
                f.write(f"   Found in comments at:\n")
                for loc in data['locations'][:3]:  # First 3 locations
                    f.write(f"      {loc['file']}:{loc['line']}\n")
            
            # USED section (summary only)
            f.write(f"\n\n✅ USED KEYS ({len(used)}):\n")
            f.write("-" * 80 + "\n")
            for key in sorted(used.keys()):
                usage_count = len(used[key]['locations'])
                f.write(f"   {key} ({usage_count} usages)\n")
        
        print(f"📄 Detailed report saved: {report_file}\n")
        
        return {
            'unused': unused,
            'comment_only': comment_only,
            'used': used,
            'report_file': report_file
        }
    
    # =================== STAGE 2: BACKUP ===================
    
    def create_backup(self):
        """Tüm ARB dosyalarının yedeğini al"""
        print("\n💾 Creating backup...")
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = f'l10n_backup_{timestamp}'
        
        try:
            os.makedirs(backup_dir, exist_ok=True)
            
            for lang, arb_path in self.arb_files.items():
                if os.path.exists(arb_path):
                    backup_path = os.path.join(backup_dir, f'app_{lang}.arb')
                    shutil.copy2(arb_path, backup_path)
                    print(f"   ✅ Backed up: {lang}")
            
            self.backup_created = True
            print(f"✅ Backup created: {backup_dir}\n")
            return backup_dir
            
        except Exception as e:
            print(f"❌ Backup failed: {e}")
            return None
    
    # =================== STAGE 3: CLEANUP ===================
    
    def remove_keys_from_arb(self, keys_to_remove, dry_run=True):
        """ARB dosyalarından key'leri sil"""
        
        if dry_run:
            print("\n🔍 DRY RUN MODE - No files will be modified")
            print("=" * 80)
        else:
            print("\n🗑️  CLEANUP MODE - Files will be modified!")
            print("=" * 80)
        
        results = {}
        
        for lang, arb_path in self.arb_files.items():
            if not os.path.exists(arb_path):
                continue
            
            try:
                # Load current file
                with open(arb_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                # Count removals
                removed_count = 0
                removed_keys = []
                
                # Remove keys (including @ metadata)
                for key in keys_to_remove:
                    if key in data:
                        if not dry_run:
                            del data[key]
                        removed_count += 1
                        removed_keys.append(key)
                    
                    # Remove @ metadata if exists
                    metadata_key = f'@{key}'
                    if metadata_key in data:
                        if not dry_run:
                            del data[metadata_key]
                
                # Save if not dry run
                if not dry_run and removed_count > 0:
                    with open(arb_path, 'w', encoding='utf-8') as f:
                        json.dump(data, f, ensure_ascii=False, indent=2)
                
                results[lang] = {
                    'removed': removed_count,
                    'keys': removed_keys
                }
                
                status = "Would remove" if dry_run else "Removed"
                print(f"   {status} {removed_count} keys from {lang}")
                
            except Exception as e:
                print(f"   ❌ Error processing {lang}: {e}")
                results[lang] = {'error': str(e)}
        
        return results
    
    # =================== STAGE 4: INTERACTIVE CLEANUP ===================
    
    def interactive_cleanup(self, analysis_results):
        """Kullanıcıyla interaktif cleanup"""
        unused = analysis_results['unused']
        comment_only = analysis_results['comment_only']
        
        print("\n" + "=" * 80)
        print("🎯 INTERACTIVE CLEANUP")
        print("=" * 80)
        
        print(f"\n📊 Found:")
        print(f"   ❌ {len(unused)} completely unused keys")
        print(f"   ⚠️  {len(comment_only)} keys only in comments")
        
        # Show some examples
        print(f"\n📋 Sample unused keys:")
        for key in list(unused.keys())[:10]:
            print(f"   - {key}: \"{unused[key]['value']}\"")
        
        if len(unused) > 10:
            print(f"   ... and {len(unused) - 10} more")
        
        print("\n" + "=" * 80)
        print("🤔 What would you like to do?")
        print("=" * 80)
        print("1. Remove ONLY completely unused keys (SAFE)")
        print("2. Remove unused + comment-only keys (MODERATE)")
        print("3. Show detailed analysis and decide manually (CAREFUL)")
        print("4. Cancel (EXIT)")
        print("=" * 80)
        
        choice = input("\nYour choice (1-4): ").strip()
        
        keys_to_remove = []
        
        if choice == '1':
            keys_to_remove = list(unused.keys())
            print(f"\n✅ Will remove {len(keys_to_remove)} completely unused keys")
        
        elif choice == '2':
            keys_to_remove = list(unused.keys()) + list(comment_only.keys())
            print(f"\n✅ Will remove {len(keys_to_remove)} keys (unused + comment-only)")
        
        elif choice == '3':
            print("\n📖 Detailed analysis:")
            print(f"Report file: {analysis_results['report_file']}")
            print("Review the report and modify this script to specify keys manually")
            return None
        
        else:
            print("\n❌ Cleanup cancelled")
            return None
        
        # Confirm before proceeding
        print("\n" + "=" * 80)
        print("⚠️  FINAL CONFIRMATION")
        print("=" * 80)
        print(f"You are about to remove {len(keys_to_remove)} keys from ALL ARB files")
        print("A backup will be created automatically")
        print("\nKeys to be removed:")
        for key in keys_to_remove[:20]:
            print(f"   - {key}")
        if len(keys_to_remove) > 20:
            print(f"   ... and {len(keys_to_remove) - 20} more")
        
        confirm = input("\n⚠️  Type 'DELETE' to confirm: ").strip()
        
        if confirm == 'DELETE':
            return keys_to_remove
        else:
            print("\n❌ Cleanup cancelled (confirmation failed)")
            return None
    
    # =================== MAIN WORKFLOW ===================
    
    def run(self):
        """Ana workflow"""
        print("\n" + "=" * 80)
        print("🚀 L10N CLEANUP SUITE")
        print("=" * 80)
        
        # Stage 1: Load and analyze
        self.load_all_arb_files()
        self.perform_deep_analysis()
        analysis_results = self.generate_detailed_report()
        
        # Ask user if they want to proceed with cleanup
        print("\n" + "=" * 80)
        proceed = input("Do you want to proceed with cleanup? (y/n): ").strip().lower()
        
        if proceed != 'y':
            print("✅ Analysis complete. Check the report file!")
            return
        
        # Stage 2: Backup
        backup_dir = self.create_backup()
        if not backup_dir:
            print("❌ Backup failed. Aborting cleanup!")
            return
        
        # Stage 3: Interactive cleanup
        keys_to_remove = self.interactive_cleanup(analysis_results)
        
        if not keys_to_remove:
            print("\n✅ No changes made")
            return
        
        # Stage 4: Dry run first
        print("\n" + "=" * 80)
        print("STEP 1: DRY RUN")
        print("=" * 80)
        self.remove_keys_from_arb(keys_to_remove, dry_run=True)
        
        # Stage 5: Actual cleanup
        final_confirm = input("\n⚠️  Proceed with actual cleanup? (y/n): ").strip().lower()
        
        if final_confirm == 'y':
            print("\n" + "=" * 80)
            print("STEP 2: ACTUAL CLEANUP")
            print("=" * 80)
            results = self.remove_keys_from_arb(keys_to_remove, dry_run=False)
            
            print("\n✅ CLEANUP COMPLETE!")
            print("=" * 80)
            print(f"📦 Backup location: {backup_dir}")
            print(f"📄 Analysis report: {analysis_results['report_file']}")
            print("\n🔧 Next steps:")
            print("1. Run: flutter gen-l10n")
            print("2. Run: flutter run")
            print("3. Test the app thoroughly")
            print("4. If issues found, restore from backup")
            print(f"\nTo restore: cp {backup_dir}/* lib/l10n/")
        else:
            print("\n❌ Cleanup cancelled at final step")

# =================== RUN ===================

if __name__ == '__main__':
    tool = L10nCleanupTool()
    tool.run()