#!/usr/bin/env python3
"""
Simple webhook test script to simulate git push events
This demonstrates the webhook-to-pipeline integration workflow
"""

import json
import subprocess
import time
from datetime import datetime

def simulate_webhook_event():
    """Simulate a Git webhook event payload"""
    webhook_payload = {
        "ref": "refs/heads/main",
        "before": "abc123old",
        "after": "def456new",
        "repository": {
            "name": "ShopSphere",
            "full_name": "Navpan18/ShopSphere",
            "html_url": "https://github.com/Navpan18/ShopSphere"
        },
        "pusher": {
            "name": "developer",
            "email": "dev@example.com"
        },
        "commits": [
            {
                "id": "def456new",
                "message": "Add new feature to ShopSphere",
                "timestamp": datetime.now().isoformat(),
                "author": {
                    "name": "Developer",
                    "email": "dev@example.com"
                },
                "added": ["src/new-feature.js"],
                "modified": ["package.json", "README.md"],
                "removed": []
            }
        ],
        "head_commit": {
            "id": "def456new",
            "message": "Add new feature to ShopSphere",
            "timestamp": datetime.now().isoformat()
        }
    }
    return webhook_payload

def trigger_jenkins_pipeline():
    """Trigger Jenkins pipeline via API"""
    print("🔗 Triggering Jenkins Pipeline...")
    
    # Try to trigger the ShopSphere-Simple job
    try:
        result = subprocess.run([
            "curl", "-X", "POST", "-u", "admin:admin",
            "http://localhost:9090/job/ShopSphere-Simple/build"
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            print("✅ Jenkins job triggered successfully!")
            return True
        else:
            print(f"❌ Failed to trigger Jenkins job: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print("⏰ Jenkins request timed out")
        return False
    except Exception as e:
        print(f"❌ Error triggering Jenkins: {e}")
        return False

def check_pipeline_status():
    """Check the status of the pipeline"""
    print("🔍 Checking pipeline status...")
    
    try:
        result = subprocess.run([
            "curl", "-s", "-u", "admin:admin",
            "http://localhost:9090/job/ShopSphere-Simple/lastBuild/api/json"
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0 and result.stdout:
            try:
                build_info = json.loads(result.stdout)
                build_number = build_info.get('number', 'Unknown')
                result_status = build_info.get('result', 'BUILDING')
                building = build_info.get('building', False)
                
                if building:
                    print(f"🔄 Build #{build_number} is currently running...")
                else:
                    print(f"📊 Build #{build_number} completed with status: {result_status}")
                
                return build_info
            except json.JSONDecodeError:
                print("❌ Failed to parse Jenkins response")
                return None
        else:
            print("❌ Failed to get pipeline status")
            return None
    except Exception as e:
        print(f"❌ Error checking pipeline status: {e}")
        return None

def main():
    """Main webhook simulation function"""
    print("🚀 ShopSphere Webhook-to-Pipeline Test")
    print("=" * 50)
    
    # Step 1: Simulate webhook event
    print("\n1️⃣ Simulating Git Push Event...")
    webhook_data = simulate_webhook_event()
    print(f"📦 Webhook payload:")
    print(f"   Repository: {webhook_data['repository']['full_name']}")
    print(f"   Branch: {webhook_data['ref'].split('/')[-1]}")
    print(f"   Commit: {webhook_data['head_commit']['id']}")
    print(f"   Message: {webhook_data['head_commit']['message']}")
    print(f"   Author: {webhook_data['pusher']['name']}")
    
    # Step 2: Trigger pipeline
    print("\n2️⃣ Processing Webhook Event...")
    pipeline_triggered = trigger_jenkins_pipeline()
    
    if not pipeline_triggered:
        print("❌ Pipeline trigger failed. Exiting...")
        return
    
    # Step 3: Monitor pipeline
    print("\n3️⃣ Monitoring Pipeline Execution...")
    
    # Wait a moment for the build to start
    time.sleep(2)
    
    # Check status a few times
    for i in range(5):
        build_info = check_pipeline_status()
        if build_info and not build_info.get('building', False):
            result = build_info.get('result', 'UNKNOWN')
            if result == 'SUCCESS':
                print("🎉 Pipeline completed successfully!")
            elif result == 'FAILURE':
                print("💥 Pipeline failed!")
            else:
                print(f"⚠️ Pipeline completed with status: {result}")
            break
        
        if i < 4:  # Don't sleep on the last iteration
            print("⏳ Waiting for pipeline to complete...")
            time.sleep(3)
    
    print("\n✅ Webhook-to-Pipeline test completed!")
    print("🔗 Jenkins UI: http://localhost:9090")
    print("🌐 Public URL (ngrok): https://818961da248f.ngrok-free.app")

if __name__ == "__main__":
    main()
