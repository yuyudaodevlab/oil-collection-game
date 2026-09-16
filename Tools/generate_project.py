#!/usr/bin/env python3
"""Reproducible Xcode project without third-party project generators."""
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parent.parent
objects = {}
def uid(key): return hashlib.sha1(key.encode()).hexdigest()[:24].upper()
def add(key, value):
    objects[uid(key)] = value
    return uid(key)
def quoted(s): return '"' + s.replace('"', '\\"') + '"'
def array(items): return '(' + ', '.join(items) + ')'

sources = sorted(root.glob('Sources/**/*.swift'))
source_refs = []
for path in sources:
    rel = str(path.relative_to(root))
    source_refs.append(add(rel, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quoted(rel)}; sourceTree = SOURCE_ROOT;'))
assets = add('assets', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Resources/Assets.xcassets; sourceTree = SOURCE_ROOT;')
privacy = add('privacy', 'isa = PBXFileReference; lastKnownFileType = text.xml; path = Resources/PrivacyInfo.xcprivacy; sourceTree = SOURCE_ROOT;')
products = []
targets = []
for name, platform, bundle in [('OilGarden', 'iphoneos', 'jp.oilgarden.app'), ('OilGardenMac', 'macosx', 'jp.oilgarden.app.mac'), ('OilGardenWatch', 'watchos', 'jp.oilgarden.app.watchkitapp')]:
    product = add(name+'product', f'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {name}.app; sourceTree = BUILT_PRODUCTS_DIR;')
    products.append(product)
    source_builds = [add(name+s, f'isa = PBXBuildFile; fileRef = {s};') for s in source_refs]
    res_builds = [add(name+r, f'isa = PBXBuildFile; fileRef = {r};') for r in [assets, privacy]]
    phases = [add(name+'sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {array(source_builds)}; runOnlyForDeploymentPostprocessing = 0;'),
              add(name+'frameworks', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;'),
              add(name+'resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {array(res_builds)}; runOnlyForDeploymentPostprocessing = 0;')]
    dependencies = []
    if platform == 'iphoneos':
        embedded = add('embedwatchfile', f'isa = PBXBuildFile; fileRef = {uid("OilGardenWatchproduct")}; settings = {{ ATTRIBUTES = (RemoveHeadersOnCopy); }};')
        phases.append(add('embedwatch', f'isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = "$(CONTENTS_FOLDER_PATH)/Watch"; dstSubfolderSpec = 16; files = ({embedded}); name = "Embed Watch Content"; runOnlyForDeploymentPostprocessing = 0;'))
        proxy = add('watchproxy', f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("OilGardenWatchtarget")}; remoteInfo = OilGardenWatch;')
        dependencies.append(add('watchdependency', f'isa = PBXTargetDependency; target = {uid("OilGardenWatchtarget")}; targetProxy = {proxy};'))
    configs = []
    for config in ['Debug', 'Release']:
        settings = {
            'PRODUCT_NAME': '$(TARGET_NAME)', 'PRODUCT_BUNDLE_IDENTIFIER': bundle,
            'SWIFT_VERSION': '5.0', 'SDKROOT': platform, 'CODE_SIGN_STYLE': 'Automatic',
            'GENERATE_INFOPLIST_FILE': 'YES', 'CURRENT_PROJECT_VERSION': '1', 'MARKETING_VERSION': '1.0',
            'INFOPLIST_KEY_CFBundleDisplayName': '油あつめ', 'INFOPLIST_KEY_LSApplicationCategoryType': 'public.app-category.games',
            'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon', 'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME': 'AccentColor',
            'SWIFT_EMIT_LOC_STRINGS': 'YES', 'ENABLE_USER_SCRIPT_SANDBOXING': 'YES',
            'SWIFT_OPTIMIZATION_LEVEL': '-Onone' if config == 'Debug' else '-O',
        }
        if platform == 'iphoneos':
            settings.update({'IPHONEOS_DEPLOYMENT_TARGET': '17.0', 'TARGETED_DEVICE_FAMILY': '1,2', 'SUPPORTED_PLATFORMS': 'iphoneos iphonesimulator', 'SUPPORTS_MACCATALYST': 'NO', 'INFOPLIST_KEY_UILaunchScreen_Generation': 'YES', 'INFOPLIST_KEY_UIApplicationSceneManifest_Generation': 'YES', 'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone': 'UIInterfaceOrientationPortrait', 'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad': 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'})
        elif platform == 'watchos':
            settings.update({'WATCHOS_DEPLOYMENT_TARGET': '10.0', 'TARGETED_DEVICE_FAMILY': '4', 'SUPPORTED_PLATFORMS': 'watchos watchsimulator', 'INFOPLIST_KEY_WKApplication': 'YES', 'INFOPLIST_KEY_WKWatchOnly': 'NO', 'INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp': 'YES', 'INFOPLIST_KEY_WKCompanionAppBundleIdentifier': 'jp.oilgarden.app', 'SKIP_INSTALL': 'YES'})
        else:
            settings.update({'MACOSX_DEPLOYMENT_TARGET': '14.0', 'SUPPORTED_PLATFORMS': 'macosx', 'ENABLE_APP_SANDBOX': 'YES', 'ENABLE_HARDENED_RUNTIME': 'YES', 'COMBINE_HIDPI_IMAGES': 'YES'})
        configs.append(add(name+config, f'isa = XCBuildConfiguration; name = {config}; buildSettings = {{' + ''.join(f'{k} = {quoted(v)};' for k,v in settings.items()) + '};'))
    configlist = add(name+'configs', f'isa = XCConfigurationList; buildConfigurations = {array(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
    targets.append(add(name+'target', f'isa = PBXNativeTarget; buildConfigurationList = {configlist}; buildPhases = {array(phases)}; buildRules = (); dependencies = {array(dependencies)}; name = {name}; productName = {name}; productReference = {product}; productType = "com.apple.product-type.application";'))

productgroup = add('products', f'isa = PBXGroup; children = {array(products)}; name = Products; sourceTree = "<group>";')
main = add('main', f'isa = PBXGroup; children = {array(source_refs + [assets, privacy, productgroup])}; sourceTree = "<group>";')
configs = []
for config in ['Debug','Release']:
    configs.append(add('project'+config, f'isa = XCBuildConfiguration; name = {config}; buildSettings = {{ CLANG_ENABLE_MODULES = YES; SWIFT_STRICT_CONCURRENCY = complete; DEBUG_INFORMATION_FORMAT = {quoted("dwarf" if config == "Debug" else "dwarf-with-dsym")}; }};'))
configlist = add('projectconfigs', f'isa = XCConfigurationList; buildConfigurations = {array(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
add('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; }}; buildConfigurationList = {configlist}; compatibilityVersion = "Xcode 14.0"; developmentRegion = ja; hasScannedForEncodings = 0; knownRegions = (ja, en, Base); mainGroup = {main}; productRefGroup = {productgroup}; projectDirPath = ""; projectRoot = ""; targets = {array(targets)};')
project = root / 'OilGarden.xcodeproj'
project.mkdir(exist_ok=True)
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n' + '\n'.join(f'{key} = {{ {value} }};' for key,value in objects.items()) + f'\n}}; rootObject = {uid("project")}; }}\n')
schemes = project / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
for name in ['OilGarden', 'OilGardenMac', 'OilGardenWatch']:
    ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid(name+"target")}" BuildableName="{name}.app" BlueprintName="{name}" ReferencedContainer="container:OilGarden.xcodeproj"/>'
    (schemes / (name+'.xcscheme')).write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"/>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Generated OilGarden.xcodeproj with iOS, macOS and watchOS schemes.')
