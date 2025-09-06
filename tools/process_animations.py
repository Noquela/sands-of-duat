#!/usr/bin/env python3
"""
⚙️ ANIMATION PROCESSOR - SANDS OF DUAT
Processa FBX do Mixamo para GLB otimizado para Godot

Features:
- Conversão FBX → GLB/GLTF
- Otimização de malhas
- Limpeza de materiais desnecessários
- Organização automática por categoria
"""

import os
import json
import shutil
import trimesh
from pathlib import Path
import subprocess
import sys

class AnimationProcessor:
    def __init__(self):
        """Inicializa o processador de animações"""
        # Load configuration
        with open("config/animation_pipeline.json", "r") as f:
            self.config = json.load(f)
        
        self.animation_renames = self.config["animation_renames"]
        self.categories = self.config["egyptian_animation_pack"]
        
        # Paths
        self.input_path = Path("temp/downloads")
        self.output_path = Path("animations/processed")
        self.godot_path = Path("godot/assets/animations")
        
        # Create output directories
        self.output_path.mkdir(parents=True, exist_ok=True)
        self.godot_path.mkdir(parents=True, exist_ok=True)
        
        print("⚙️ Animation Processor initialized")
        print(f"📂 Input: {self.input_path}")
        print(f"📂 Output: {self.output_path}")
        print(f"🎮 Godot: {self.godot_path}")
    
    def check_dependencies(self):
        """Verifica se as dependências estão instaladas"""
        print("🔍 Checking dependencies...")
        
        # Check trimesh
        try:
            import trimesh
            print("  ✅ trimesh available")
        except ImportError:
            print("  ❌ trimesh not found - installing...")
            subprocess.run([sys.executable, "-m", "pip", "install", "trimesh"])
        
        # Check if Blender is available (optional but recommended)
        blender_paths = [
            "blender",  # In PATH
            "C:/Program Files/Blender Foundation/Blender 4.0/blender.exe",
            "C:/Program Files/Blender Foundation/Blender 3.6/blender.exe",
        ]
        
        self.blender_path = None
        for path in blender_paths:
            try:
                result = subprocess.run([path, "--version"], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    self.blender_path = path
                    print(f"  ✅ Blender found: {path}")
                    break
            except:
                continue
        
        if not self.blender_path:
            print("  ⚠️  Blender not found - using basic conversion")
        
        return True
    
    def convert_fbx_to_glb_blender(self, fbx_path, glb_path):
        """Converte FBX para GLB usando Blender (melhor qualidade)"""
        if not self.blender_path:
            return False
        
        # Blender Python script for conversion
        blend_script = f'''
import bpy
import os

# Clear default scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Import FBX
bpy.ops.import_scene.fbx(filepath="{fbx_path}")

# Export as GLB
bpy.ops.export_scene.gltf(
    filepath="{glb_path}",
    export_format='GLB',
    export_animations=True,
    export_optimize_animations=True,
    export_anim_optimize_precision=0.05,
    export_frame_range=True
)

# Quit Blender
bpy.ops.wm.quit_blender()
'''
        
        # Write script to temp file
        script_path = Path("temp/convert_script.py")
        script_path.parent.mkdir(exist_ok=True)
        with open(script_path, "w") as f:
            f.write(blend_script)
        
        try:
            # Run Blender with script
            cmd = [self.blender_path, "--background", "--python", str(script_path)]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0 and Path(glb_path).exists():
                print(f"    ✅ Blender conversion successful")
                os.remove(script_path)
                return True
            else:
                print(f"    ❌ Blender conversion failed: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            print(f"    ⏱️ Blender conversion timeout")
        except Exception as e:
            print(f"    ❌ Blender error: {e}")
        
        # Cleanup
        if script_path.exists():
            os.remove(script_path)
        
        return False
    
    def convert_fbx_to_glb_trimesh(self, fbx_path, glb_path):
        """Converte FBX para GLB usando trimesh (fallback básico)"""
        try:
            # Load FBX mesh
            mesh = trimesh.load(fbx_path)
            
            if isinstance(mesh, trimesh.Scene):
                # Scene with multiple meshes
                combined = None
                for name, geometry in mesh.geometry.items():
                    if combined is None:
                        combined = geometry
                    else:
                        combined += geometry
                mesh = combined
            
            if mesh is None:
                print(f"    ❌ Could not load mesh from {fbx_path}")
                return False
            
            # Basic optimization
            mesh.remove_duplicate_faces()
            mesh.remove_unreferenced_vertices()
            
            # Export as GLB
            mesh.export(glb_path)
            
            print(f"    ✅ Trimesh conversion successful")
            return True
            
        except Exception as e:
            print(f"    ❌ Trimesh conversion failed: {e}")
            return False
    
    def process_single_animation(self, fbx_file):
        """Processa uma única animação"""
        fbx_path = self.input_path / fbx_file
        animation_name = fbx_file.stem
        
        print(f"⚙️ Processing: {animation_name}")
        
        # Determine output paths
        glb_output = self.output_path / f"{animation_name}.glb"
        godot_output = self.godot_path / f"{animation_name}.glb"
        
        # Try Blender conversion first (better quality)
        success = False
        if self.blender_path:
            success = self.convert_fbx_to_glb_blender(str(fbx_path), str(glb_output))
        
        # Fallback to trimesh if Blender fails
        if not success:
            print(f"    📦 Using trimesh fallback...")
            success = self.convert_fbx_to_glb_trimesh(str(fbx_path), str(glb_output))
        
        if success and glb_output.exists():
            # Copy to Godot assets
            shutil.copy2(glb_output, godot_output)
            
            # Log file info
            file_size = glb_output.stat().st_size / 1024  # KB
            print(f"    📊 Size: {file_size:.1f} KB")
            print(f"    ✅ Ready for Godot")
            
            return True
        else:
            print(f"    ❌ Processing failed")
            return False
    
    def organize_by_categories(self):
        """Organiza animações por categorias no Godot"""
        print("📁 Organizing animations by categories...")
        
        # Create category folders
        for category in self.categories.keys():
            category_path = self.godot_path / category
            category_path.mkdir(exist_ok=True)
        
        # Move files to appropriate categories
        for category, animations in self.categories.items():
            category_path = self.godot_path / category
            
            for original_name in animations:
                # Get renamed file name
                renamed = self.animation_renames.get(original_name, 
                                                   original_name.lower().replace(" ", "_"))
                
                glb_file = self.godot_path / f"{renamed}.glb"
                target_path = category_path / f"{renamed}.glb"
                
                if glb_file.exists():
                    shutil.move(str(glb_file), str(target_path))
                    print(f"  📁 {category}/{renamed}.glb")
        
        print("✅ Animation organization complete")
    
    def create_godot_import_files(self):
        """Cria arquivos .import para otimizar importação no Godot"""
        print("🎮 Creating Godot import files...")
        
        # Template for GLB import
        import_template = '''[remap]

importer="scene"
type="PackedScene"
uid="uid://PLACEHOLDER_UID"
path="res://.godot/imported/{filename}.{extension}-{hash}.scn"

[deps]

source_file="res://assets/animations/{filepath}"
dest_files=["res://.godot/imported/{filename}.{extension}-{hash}.scn"]

[params]

nodes/root_type=""
nodes/root_name=""
nodes/apply_root_scale=true
nodes/root_scale=1.0
meshes/ensure_tangents=true
meshes/generate_lods=true
meshes/create_shadow_meshes=true
meshes/light_baking=1
meshes/lightmap_texel_size=0.2
meshes/force_disable_compression=false
skins/use_named_skins=true
animation/import=true
animation/fps=30
animation/trimming=false
animation/remove_immutable_tracks=true
animation/import_rest_as_RESET=false
import_script/path=""
_subresources={{}}
gltf/naming_version=1
gltf/embedded_image_handling=1
'''
        
        # Create import files for each GLB
        for glb_file in self.godot_path.rglob("*.glb"):
            import_file = glb_file.with_suffix(".glb.import")
            
            # Get relative path from assets/animations/
            rel_path = glb_file.relative_to(self.godot_path)
            
            # Create import content
            import_content = import_template.format(
                filename=glb_file.stem,
                extension="glb",
                filepath=rel_path.as_posix(),
                hash="placeholder"  # Godot will generate this
            )
            
            with open(import_file, "w") as f:
                f.write(import_content)
        
        print("✅ Godot import files created")
    
    def generate_summary_report(self):
        """Gera relatório resumo do processamento"""
        print("📊 Generating processing summary...")
        
        # Count processed files
        glb_files = list(self.output_path.glob("*.glb"))
        godot_files = list(self.godot_path.rglob("*.glb"))
        
        # Calculate total size
        total_size = sum(f.stat().st_size for f in glb_files) / (1024 * 1024)  # MB
        
        # Category breakdown
        category_counts = {}
        for category in self.categories.keys():
            category_path = self.godot_path / category
            if category_path.exists():
                count = len(list(category_path.glob("*.glb")))
                category_counts[category] = count
        
        # Generate report
        report = {
            "processing_summary": {
                "total_processed": len(glb_files),
                "total_godot_ready": len(godot_files),
                "total_size_mb": round(total_size, 2),
                "categories": category_counts
            },
            "file_list": [f.name for f in glb_files],
            "godot_structure": {
                category: [f.name for f in (self.godot_path / category).glob("*.glb")] 
                if (self.godot_path / category).exists() else []
                for category in self.categories.keys()
            }
        }
        
        # Save report
        report_path = Path("logs/processing_report.json")
        report_path.parent.mkdir(exist_ok=True)
        with open(report_path, "w") as f:
            json.dump(report, f, indent=2)
        
        # Print summary
        print("\n📊 PROCESSING SUMMARY")
        print("=" * 50)
        print(f"✅ Total processed: {len(glb_files)}")
        print(f"🎮 Godot ready: {len(godot_files)}")
        print(f"📦 Total size: {total_size:.2f} MB")
        print(f"📁 Report saved: {report_path}")
        
        print(f"\n📂 Category breakdown:")
        for category, count in category_counts.items():
            print(f"   {category}: {count} animations")
        
        return report
    
    def process_all_animations(self):
        """Processa todas as animações FBX"""
        fbx_files = list(self.input_path.glob("*.fbx"))
        
        if not fbx_files:
            print("❌ No FBX files found in temp/downloads/")
            print("   Run mixamo_automation.py first to download animations")
            return False
        
        print(f"🎬 Found {len(fbx_files)} FBX animations to process")
        print("=" * 60)
        
        success_count = 0
        failed_files = []
        
        # Process each FBX file
        for i, fbx_file in enumerate(fbx_files, 1):
            print(f"\n[{i}/{len(fbx_files)}] {fbx_file.name}")
            
            try:
                if self.process_single_animation(fbx_file.name):
                    success_count += 1
                else:
                    failed_files.append(fbx_file.name)
                    
            except Exception as e:
                print(f"    💥 Error: {e}")
                failed_files.append(fbx_file.name)
        
        # Post-processing
        if success_count > 0:
            print(f"\n🔄 Post-processing {success_count} animations...")
            self.organize_by_categories()
            self.create_godot_import_files()
            self.generate_summary_report()
        
        # Final results
        print(f"\n🏆 PROCESSING COMPLETE")
        print("=" * 60)
        print(f"✅ Success: {success_count}")
        print(f"❌ Failed: {len(failed_files)}")
        
        if failed_files:
            print(f"\n⚠️  Failed files:")
            for file in failed_files:
                print(f"   - {file}")
        
        return success_count > 0

def main():
    """Execução principal"""
    print("⚙️ ANIMATION PROCESSOR")
    print("🏛️ Sands of Duat - FBX to GLB Conversion")
    print("=" * 50)
    
    processor = AnimationProcessor()
    
    try:
        # Check dependencies
        processor.check_dependencies()
        
        # Process all animations
        success = processor.process_all_animations()
        
        if success:
            print("\n🎉 ANIMATION PROCESSING COMPLETED!")
            print("📁 Check godot/assets/animations/ for organized GLB files")
            print("🔄 Next step: Import in Godot and setup AnimationTree")
        else:
            print("\n❌ Processing failed or no animations found")
            
    except Exception as e:
        print(f"\n💥 Critical error: {e}")

if __name__ == "__main__":
    main()