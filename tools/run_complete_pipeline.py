#!/usr/bin/env python3
"""
🚀 COMPLETE ANIMATION PIPELINE - SANDS OF DUAT
Executa todo o pipeline de animação: Setup → Download → Processing → Import

EXECUÇÃO ÚNICA:
python run_complete_pipeline.py

RESULTADO:
✅ 42 animações AAA do Mixamo
✅ Processadas e otimizadas para Godot
✅ Organizadas por categoria
✅ Prontas para usar no jogo
"""

import os
import sys
import time
import json
import subprocess
from pathlib import Path

class CompletePipeline:
    def __init__(self):
        """Inicializa o pipeline completo"""
        self.start_time = time.time()
        self.project_root = Path.cwd()
        
        print("🚀 SANDS OF DUAT - COMPLETE ANIMATION PIPELINE")
        print("🏛️ Professional Egyptian Animation System")
        print("=" * 60)
        print(f"📂 Project root: {self.project_root}")
        
        # Pipeline steps
        self.steps = [
            ("🔧 Setup", self.run_setup),
            ("🤖 Download Animations", self.run_download),
            ("⚙️ Process Animations", self.run_processing),
            ("📋 Generate Report", self.generate_final_report)
        ]
        
        # Results tracking
        self.results = {
            "pipeline_start": time.time(),
            "steps_completed": [],
            "steps_failed": [],
            "total_animations": 42,
            "downloaded": 0,
            "processed": 0,
            "errors": []
        }
    
    def print_step_header(self, step_name, step_num, total_steps):
        """Imprime cabeçalho do step"""
        print(f"\n{'='*60}")
        print(f"STEP {step_num}/{total_steps}: {step_name}")
        print(f"{'='*60}")
    
    def run_setup(self):
        """Executa setup do pipeline"""
        print("🔧 Running pipeline setup...")
        
        try:
            # Run setup script
            result = subprocess.run([sys.executable, "tools/setup_animation_pipeline.py"], 
                                  capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ Setup completed successfully")
                print(result.stdout)
                return True
            else:
                print(f"❌ Setup failed: {result.stderr}")
                self.results["errors"].append(f"Setup error: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Setup error: {e}")
            self.results["errors"].append(f"Setup exception: {e}")
            return False
    
    def check_adobe_credentials(self):
        """Verifica se credenciais Adobe estão configuradas"""
        print("🔐 Checking Adobe credentials...")
        
        # Read automation script to check credentials
        automation_path = self.project_root / "tools/mixamo_automation.py"
        
        if not automation_path.exists():
            print("❌ mixamo_automation.py not found")
            return False
        
        with open(automation_path, "r") as f:
            content = f.read()
        
        # Check if placeholder credentials are still there
        if "exemplo.com" in content or "SEU_EMAIL" in content:
            print("\n⚠️  ADOBE CREDENTIALS NOT CONFIGURED")
            print("📋 To configure your Adobe account:")
            print("   1. Edit tools/mixamo_automation.py")
            print("   2. Replace EMAIL and PASSWORD with your Adobe account")
            print("   3. Adobe accounts are FREE at: https://account.adobe.com")
            print("\n🔄 Run again after configuring credentials")
            return False
        
        print("✅ Adobe credentials configured")
        return True
    
    def run_download(self):
        """Executa download das animações"""
        print("🤖 Starting Mixamo automation...")
        
        # Check credentials first
        if not self.check_adobe_credentials():
            return False
        
        try:
            # Run Mixamo automation
            print("📥 Downloading 42 Egyptian animations from Mixamo...")
            print("⏱️  This may take 15-20 minutes...")
            
            result = subprocess.run([sys.executable, "tools/mixamo_automation.py"],
                                  cwd=self.project_root)
            
            if result.returncode == 0:
                # Check download results
                log_path = self.project_root / "logs/download_results.json"
                if log_path.exists():
                    with open(log_path, "r") as f:
                        download_data = json.load(f)
                    
                    self.results["downloaded"] = download_data.get("successful", 0)
                    success_rate = download_data.get("success_rate", 0)
                    
                    print(f"✅ Download completed: {self.results['downloaded']} animations")
                    print(f"📊 Success rate: {success_rate:.1f}%")
                    
                    if success_rate >= 80:  # Allow some failures
                        return True
                    else:
                        print("⚠️  Too many download failures")
                        return False
                else:
                    print("⚠️  Could not verify download results")
                    return False
            else:
                print(f"❌ Download failed with return code: {result.returncode}")
                return False
                
        except Exception as e:
            print(f"❌ Download error: {e}")
            self.results["errors"].append(f"Download exception: {e}")
            return False
    
    def run_processing(self):
        """Executa processamento das animações"""
        print("⚙️ Processing FBX animations to GLB...")
        
        try:
            # Run animation processor
            result = subprocess.run([sys.executable, "tools/process_animations.py"],
                                  cwd=self.project_root)
            
            if result.returncode == 0:
                # Check processing results
                report_path = self.project_root / "logs/processing_report.json"
                if report_path.exists():
                    with open(report_path, "r") as f:
                        process_data = json.load(f)
                    
                    summary = process_data.get("processing_summary", {})
                    self.results["processed"] = summary.get("total_processed", 0)
                    
                    print(f"✅ Processing completed: {self.results['processed']} animations")
                    print(f"📦 Total size: {summary.get('total_size_mb', 0)} MB")
                    print(f"🎮 Godot ready: {summary.get('total_godot_ready', 0)} files")
                    
                    return True
                else:
                    print("⚠️  Could not verify processing results")
                    return False
            else:
                print(f"❌ Processing failed with return code: {result.returncode}")
                return False
                
        except Exception as e:
            print(f"❌ Processing error: {e}")
            self.results["errors"].append(f"Processing exception: {e}")
            return False
    
    def generate_final_report(self):
        """Gera relatório final do pipeline"""
        print("📋 Generating final pipeline report...")
        
        end_time = time.time()
        duration = end_time - self.start_time
        
        # Complete results
        self.results.update({
            "pipeline_end": end_time,
            "total_duration_seconds": duration,
            "total_duration_minutes": duration / 60,
            "success_rate": (len(self.results["steps_completed"]) / len(self.steps)) * 100
        })
        
        # File structure analysis
        godot_animations = self.project_root / "godot/assets/animations"
        if godot_animations.exists():
            glb_files = list(godot_animations.rglob("*.glb"))
            self.results["final_godot_files"] = len(glb_files)
        
        # Save complete report
        report_path = self.project_root / "logs/complete_pipeline_report.json"
        report_path.parent.mkdir(exist_ok=True)
        
        with open(report_path, "w") as f:
            json.dump(self.results, f, indent=2)
        
        # Print final summary
        self.print_final_summary(duration)
        
        return True
    
    def print_final_summary(self, duration):
        """Imprime resumo final"""
        print("\n" + "🏆" * 60)
        print("PIPELINE EXECUTION COMPLETE")
        print("🏆" * 60)
        
        print(f"\n📊 EXECUTION SUMMARY:")
        print(f"   ⏱️  Total time: {duration/60:.1f} minutes")
        print(f"   ✅ Steps completed: {len(self.results['steps_completed'])}/{len(self.steps)}")
        print(f"   📥 Downloaded: {self.results['downloaded']} animations")
        print(f"   ⚙️  Processed: {self.results['processed']} animations")
        print(f"   🎮 Godot ready: {self.results.get('final_godot_files', 0)} files")
        
        if self.results["errors"]:
            print(f"\n⚠️  ERRORS ENCOUNTERED:")
            for error in self.results["errors"]:
                print(f"   - {error}")
        
        # Success determination
        success = (len(self.results["steps_completed"]) >= 3 and 
                  self.results["processed"] > 0)
        
        if success:
            print(f"\n🎉 PIPELINE SUCCESS!")
            print(f"📁 Animation files ready in: godot/assets/animations/")
            print(f"📋 Import these GLB files into your Godot project")
            print(f"🔄 Use AnimationTree for smooth transitions")
            
            print(f"\n🎮 NEXT STEPS:")
            print(f"   1. Open Godot and import animations")
            print(f"   2. Create AnimationTree for your character")
            print(f"   3. Setup state machine for combat/locomotion")
            print(f"   4. Test Egyptian animation system!")
        else:
            print(f"\n❌ PIPELINE INCOMPLETE")
            print(f"   Check errors above and retry failed steps")
        
        print(f"\n📋 Full report: logs/complete_pipeline_report.json")
    
    def run_complete_pipeline(self):
        """Executa o pipeline completo"""
        print(f"🚀 Starting complete pipeline execution...")
        print(f"⏱️  Expected duration: ~30 minutes")
        print(f"🎯 Target: 42 professional Egyptian animations")
        
        # Execute each step
        for i, (step_name, step_func) in enumerate(self.steps, 1):
            self.print_step_header(step_name, i, len(self.steps))
            
            step_start = time.time()
            
            try:
                success = step_func()
                step_duration = time.time() - step_start
                
                if success:
                    print(f"✅ {step_name} completed in {step_duration:.1f}s")
                    self.results["steps_completed"].append(step_name)
                else:
                    print(f"❌ {step_name} failed after {step_duration:.1f}s")
                    self.results["steps_failed"].append(step_name)
                    
                    # For critical steps, ask if user wants to continue
                    if i <= 2:  # Setup and Download are critical
                        response = input(f"\n🤔 Continue with remaining steps? (y/N): ")
                        if response.lower() != 'y':
                            print("🔄 Pipeline stopped by user")
                            break
                
            except KeyboardInterrupt:
                print(f"\n⚠️  Pipeline interrupted by user")
                break
            except Exception as e:
                print(f"💥 Critical error in {step_name}: {e}")
                self.results["steps_failed"].append(step_name)
                self.results["errors"].append(f"{step_name}: {e}")
                break
        
        # Always generate final report
        if "📋 Generate Report" not in [step[0] for step in self.results["steps_completed"]]:
            self.generate_final_report()

def main():
    """Função principal"""
    print("🏛️ SANDS OF DUAT - PROFESSIONAL ANIMATION PIPELINE")
    print("🎬 Automated Egyptian Animation System")
    print("=" * 60)
    print("🎯 OBJECTIVE: Download + Process 42 AAA animations")
    print("⏱️  DURATION: ~30 minutes automated")
    print("💰 COST: $0 (Adobe free account)")
    print("🔥 QUALITY: Disney/Pixar level animations")
    print("=" * 60)
    
    # Confirmation
    response = input("🚀 Start complete pipeline? (y/N): ")
    if response.lower() != 'y':
        print("🔄 Pipeline cancelled")
        return
    
    # Execute pipeline
    pipeline = CompletePipeline()
    pipeline.run_complete_pipeline()

if __name__ == "__main__":
    main()