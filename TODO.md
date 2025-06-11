# 🎵 QuickLoops - Renaming Action Plan

## 📋 **Systematic Renaming from MiniLooper/MinimalLooper to QuickLoops**

### **✅ COMPLETED TASKS**
- [x] Created comprehensive naming audit
- [x] Documented action plan

### **🚨 CRITICAL PUBLIC-FACING CHANGES**

#### **Step 1: Update Xcode Project Settings** ✅ COMPLETED
- [x] Update bundle identifier: `com.pmoneymusic.minimallooper` → `com.pmoneymusic.quickloops`
- [x] Update app display name references in project.pbxproj
- [x] Update microphone permission text: `"MinimalLooper needs microphone access..."` → `"QuickLoops needs microphone access..."`
- [x] Update product name references throughout project.pbxproj

#### **Step 2: Rename Main App Structure** ✅ COMPLETED
- [x] Rename `MinimalLooperApp.swift` → `QuickLoopsApp.swift`
- [x] Update struct name: `MinimalLooperApp` → `QuickLoopsApp`
- [x] Update file references in project.pbxproj

#### **Step 3: Update MIDI Client Registration** ✅ COMPLETED
- [x] Update MIDI client name in `Audio/MIDIManager.swift`: `"MiniLooper"` → `"QuickLoops"`
- [x] Update MIDI input port name: `"MiniLooperInput"` → `"QuickLoopsInput"`

#### **Step 4: Update Documentation Files** ✅ COMPLETED
- [x] Update `README.md` title and all references
- [x] Update `IMPLEMENTATION_DOC.md` title and descriptions
- [x] Update `MIDI_IMPLEMENTATION_PROMPT.md` app name references

#### **Step 5: Directory & File Structure Cleanup** ✅ PARTIALLY COMPLETED
- [ ] Rename `MinimalLooper/` directory → `QuickLoops/` *(Optional - see note below)*
- [x] Rename `MinimalLooper.entitlements` → `QuickLoops.entitlements`
- [x] Update all path references in project files

### **🔧 TECHNICAL NOTES**
- Bundle identifier change will require new app signing
- MIDI client names appear in system MIDI settings
- **Directory renaming is optional** - internal directory structure doesn't affect public app naming
- All public-facing elements have been successfully updated to "QuickLoops"

### **⚠️ TESTING CHECKLIST**
- [ ] App builds successfully
- [ ] MIDI functionality works with new client names
- [ ] App permissions request shows correct app name
- [ ] Bundle identifier is correctly updated

### **✅ RENAMING COMPLETE**
**All critical public-facing components have been successfully renamed to "QuickLoops":**
- ✅ Bundle identifier: `com.pmoneymusic.quickloops`
- ✅ App display name: "QuickLoops"
- ✅ Microphone permission text: "QuickLoops needs microphone access..."
- ✅ MIDI client registration: "QuickLoops" and "QuickLoopsInput"
- ✅ Main app struct: `QuickLoopsApp`
- ✅ All documentation updated
- ✅ Entitlements file renamed

---
**Status:** In Progress  
**Priority:** High - Required for public release  
**Estimated Time:** 1-2 hours 