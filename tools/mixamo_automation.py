#!/usr/bin/env python3
"""
🤖 MIXAMO AUTOMATION - SANDS OF DUAT
Automação completa para download de animações do Mixamo usando Selenium

CREDENCIAIS ADOBE (Configurar antes de usar):
EMAIL = "seu_email@exemplo.com"  
PASSWORD = "sua_senha_adobe"
"""

import os
import json
import time
import requests
from pathlib import Path
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException
from webdriver_manager.chrome import ChromeDriverManager

class MixamoAutomation:
    def __init__(self, email=None, password=None):
        """Inicializa automação do Mixamo"""
        # CONFIGURAR SUAS CREDENCIAIS ADOBE AQUI:
        self.email = email or "SEU_EMAIL_ADOBE@exemplo.com"
        self.password = password or "SUA_SENHA_ADOBE"
        
        if "exemplo.com" in self.email:
            print("⚠️  ATENÇÃO: Configure suas credenciais Adobe no script!")
            print("   Edite mixamo_automation.py e substitua o email/senha")
            return
        
        self.driver = None
        self.logged_in = False
        
        # Carregar configurações
        with open("config/animation_pipeline.json", "r") as f:
            self.config = json.load(f)
        
        self.animations = self.config["egyptian_animation_pack"]
        self.animation_renames = self.config["animation_renames"]
        
        print(f"🤖 Mixamo Automation initialized")
        print(f"📧 Email: {self.email}")
        print(f"🎬 Total animations: {sum(len(category) for category in self.animations.values())}")
    
    def setup_driver(self):
        """Configura o Chrome WebDriver"""
        print("🔧 Setting up Chrome WebDriver...")
        
        # Download path para FBX files
        download_path = os.path.abspath("temp/downloads")
        os.makedirs(download_path, exist_ok=True)
        
        # Chrome options
        chrome_options = Options()
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--window-size=1920,1080")
        
        # Download preferences
        prefs = {
            "download.default_directory": download_path,
            "download.prompt_for_download": False,
            "download.directory_upgrade": True,
            "safebrowsing.enabled": True
        }
        chrome_options.add_experimental_option("prefs", prefs)
        
        # Setup WebDriver
        service = Service(ChromeDriverManager().install())
        self.driver = webdriver.Chrome(service=service, options=chrome_options)
        self.driver.implicitly_wait(10)
        
        print("✅ Chrome WebDriver configured")
    
    def login_adobe(self):
        """Login na conta Adobe"""
        if self.logged_in:
            return True
        
        print("🔐 Logging into Adobe account...")
        
        try:
            # Ir para Mixamo
            self.driver.get("https://www.mixamo.com/")
            time.sleep(3)
            
            # Click Sign In
            sign_in_btn = WebDriverWait(self.driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Sign In')]"))
            )
            sign_in_btn.click()
            time.sleep(2)
            
            # Enter email
            email_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.ID, "EmailPage-EmailField"))
            )
            email_field.clear()
            email_field.send_keys(self.email)
            
            # Click Continue
            continue_btn = self.driver.find_element(By.ID, "EmailPage-ContinueButton")
            continue_btn.click()
            time.sleep(2)
            
            # Enter password
            password_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.ID, "PasswordPage-PasswordField"))
            )
            password_field.clear()
            password_field.send_keys(self.password)
            
            # Click Continue
            continue_btn = self.driver.find_element(By.ID, "PasswordPage-ContinueButton")
            continue_btn.click()
            time.sleep(5)
            
            # Verificar se login foi bem-sucedido
            WebDriverWait(self.driver, 15).until(
                EC.presence_of_element_located((By.CLASS_NAME, "mixamo-header"))
            )
            
            self.logged_in = True
            print("✅ Adobe login successful")
            return True
            
        except Exception as e:
            print(f"❌ Login failed: {e}")
            return False
    
    def search_animation(self, animation_name):
        """Busca animação específica no Mixamo"""
        print(f"🔍 Searching for: {animation_name}")
        
        try:
            # Clear search and search for animation
            search_box = WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.ID, "search-input"))
            )
            search_box.clear()
            search_box.send_keys(animation_name)
            time.sleep(2)
            
            # Click first result
            first_result = WebDriverWait(self.driver, 10).until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, ".animation-tile:first-child"))
            )
            first_result.click()
            time.sleep(3)
            
            print(f"✅ Animation found: {animation_name}")
            return True
            
        except Exception as e:
            print(f"❌ Failed to find animation {animation_name}: {e}")
            return False
    
    def configure_export_settings(self):
        """Configura as configurações de export do FBX"""
        try:
            # Open export settings
            export_btn = WebDriverWait(self.driver, 10).until(
                EC.element_to_be_clickable((By.ID, "export-button"))
            )
            export_btn.click()
            time.sleep(2)
            
            # Set format to FBX
            format_dropdown = self.driver.find_element(By.ID, "format-dropdown")
            format_dropdown.click()
            time.sleep(1)
            
            fbx_option = self.driver.find_element(By.XPATH, "//option[@value='fbx7_2019_binary']")
            fbx_option.click()
            time.sleep(1)
            
            # Enable "With Skin" checkbox
            skin_checkbox = self.driver.find_element(By.ID, "with-skin")
            if not skin_checkbox.is_selected():
                skin_checkbox.click()
            
            # Set FPS to 30
            fps_input = self.driver.find_element(By.ID, "fps-input")
            fps_input.clear()
            fps_input.send_keys("30")
            
            print("✅ Export settings configured")
            return True
            
        except Exception as e:
            print(f"❌ Failed to configure export settings: {e}")
            return False
    
    def download_animation(self, animation_name):
        """Download da animação configurada"""
        try:
            # Click download button
            download_btn = WebDriverWait(self.driver, 10).until(
                EC.element_to_be_clickable((By.ID, "download-button"))
            )
            download_btn.click()
            
            print(f"📥 Download started: {animation_name}")
            
            # Wait for download to complete (check file exists)
            download_path = Path("temp/downloads")
            timeout = 60  # 1 minute timeout
            start_time = time.time()
            
            while time.time() - start_time < timeout:
                # Check for any FBX file in download folder
                fbx_files = list(download_path.glob("*.fbx"))
                if fbx_files:
                    # Rename file to our convention
                    latest_file = max(fbx_files, key=os.path.getctime)
                    new_name = self.animation_renames.get(animation_name, animation_name.lower().replace(" ", "_"))
                    new_path = download_path / f"{new_name}.fbx"
                    latest_file.rename(new_path)
                    
                    print(f"✅ Download complete: {new_name}.fbx")
                    return True
                
                time.sleep(2)
            
            print(f"⏱️ Download timeout: {animation_name}")
            return False
            
        except Exception as e:
            print(f"❌ Download failed: {e}")
            return False
    
    def process_animation_category(self, category_name, animations):
        """Processa uma categoria completa de animações"""
        print(f"\n🎬 Processing category: {category_name.upper()}")
        print(f"   Animations: {len(animations)}")
        
        success_count = 0
        failed_animations = []
        
        for i, animation_name in enumerate(animations, 1):
            print(f"\n[{i}/{len(animations)}] Processing: {animation_name}")
            
            try:
                # Search animation
                if not self.search_animation(animation_name):
                    failed_animations.append(animation_name)
                    continue
                
                # Configure export
                if not self.configure_export_settings():
                    failed_animations.append(animation_name)
                    continue
                
                # Download animation
                if not self.download_animation(animation_name):
                    failed_animations.append(animation_name)
                    continue
                
                success_count += 1
                time.sleep(3)  # Delay between downloads
                
            except Exception as e:
                print(f"❌ Error processing {animation_name}: {e}")
                failed_animations.append(animation_name)
                continue
        
        print(f"\n📊 Category {category_name} Summary:")
        print(f"   ✅ Success: {success_count}")
        print(f"   ❌ Failed: {len(failed_animations)}")
        
        if failed_animations:
            print(f"   Failed animations: {failed_animations}")
        
        return success_count, failed_animations
    
    def download_all_animations(self):
        """Download de todas as 42 animações egípcias"""
        if not self.login_adobe():
            return False
        
        print("\n🚀 STARTING COMPLETE ANIMATION DOWNLOAD")
        print("=" * 60)
        
        total_success = 0
        total_failed = []
        
        # Process each category
        for category_name, animations in self.animations.items():
            success, failed = self.process_animation_category(category_name, animations)
            total_success += success
            total_failed.extend(failed)
        
        # Final summary
        print("\n🏆 FINAL SUMMARY")
        print("=" * 60)
        print(f"✅ Total successful downloads: {total_success}")
        print(f"❌ Total failed downloads: {len(total_failed)}")
        print(f"📊 Success rate: {(total_success/(total_success+len(total_failed)))*100:.1f}%")
        
        if total_failed:
            print(f"\n⚠️  Failed animations:")
            for anim in total_failed:
                print(f"   - {anim}")
        
        # Save results to log
        results = {
            "timestamp": time.time(),
            "total_animations": total_success + len(total_failed),
            "successful": total_success,
            "failed": len(total_failed),
            "failed_list": total_failed,
            "success_rate": (total_success/(total_success+len(total_failed)))*100
        }
        
        log_path = Path("logs/download_results.json")
        log_path.parent.mkdir(exist_ok=True)
        with open(log_path, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n📋 Results saved to: {log_path}")
        return total_success > 0
    
    def cleanup(self):
        """Limpa recursos e fecha navegador"""
        if self.driver:
            self.driver.quit()
            print("🧹 Browser closed")

def main():
    """Execução principal"""
    print("🎬 MIXAMO ANIMATION DOWNLOADER")
    print("🏛️ Sands of Duat - Egyptian Animation Pack")
    print("=" * 50)
    
    # CONFIGURE SUAS CREDENCIAIS AQUI:
    EMAIL = "SEU_EMAIL_ADOBE@exemplo.com"
    PASSWORD = "SUA_SENHA_ADOBE"
    
    automation = MixamoAutomation(email=EMAIL, password=PASSWORD)
    
    try:
        automation.setup_driver()
        success = automation.download_all_animations()
        
        if success:
            print("\n🎉 ANIMATION DOWNLOAD COMPLETED!")
            print("📁 Check temp/downloads/ for FBX files")
            print("🔄 Next step: Run process_animations.py")
        else:
            print("\n❌ Download process failed")
            
    except Exception as e:
        print(f"\n💥 Critical error: {e}")
        
    finally:
        automation.cleanup()

if __name__ == "__main__":
    main()