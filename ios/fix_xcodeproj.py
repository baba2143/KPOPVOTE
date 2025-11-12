#!/usr/bin/env python3
"""
Xcode project.pbxproj file fixer
Adds all Swift files to the project automatically
"""

import os
import re
import hashlib
from pathlib import Path

# Project paths
PROJECT_DIR = "/Users/makotobaba/Desktop/KPOPVOTE/ios/KPOPVOTE"
KPOPVOTE_DIR = os.path.join(PROJECT_DIR, "KPOPVOTE")
PBXPROJ_PATH = os.path.join(PROJECT_DIR, "KPOPVOTE.xcodeproj/project.pbxproj")

# Files to add with their group paths
FILES_TO_ADD = [
    ("AuthService.swift", "Services", "Services/AuthService.swift"),
    ("TaskService.swift", "Services", "Services/TaskService.swift"),
    ("Bias.swift", "Models", "Models/Bias.swift"),
    ("Task.swift", "Models", "Models/Task.swift"),
    ("User.swift", "Models", "Models/User.swift"),
    ("Constants.swift", "Utilities", "Utilities/Constants.swift"),
    ("ContentView.swift", "KPOPVOTE", "ContentView.swift"),
    ("KPOPVOTEApp.swift", "KPOPVOTE", "KPOPVOTEApp.swift"),
    ("LoginView.swift", "Views/Auth", "Views/Auth/LoginView.swift"),
    ("RegisterView.swift", "Views/Auth", "Views/Auth/RegisterView.swift"),
    ("MainTabView.swift", "Views", "Views/MainTabView.swift"),
    ("CommunityActivityView.swift", "Views/Home", "Views/Home/CommunityActivityView.swift"),
    ("UrgentVoteCard.swift", "Views/Home", "Views/Home/UrgentVoteCard.swift"),
]

# Skip files already in project
SKIP_FILES = ["AuthViewModel.swift", "HomeViewModel.swift"]


def generate_uuid(text):
    """Generate Xcode-style 24-character hex UUID"""
    hash_obj = hashlib.md5(text.encode())
    return hash_obj.hexdigest()[:24].upper()


def create_file_reference(filename, relative_path):
    """Create PBXFileReference entry"""
    uuid = generate_uuid(f"fileref_{relative_path}")
    return uuid, f'\t\t{uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};'


def create_build_file(filename, file_ref_uuid):
    """Create PBXBuildFile entry"""
    uuid = generate_uuid(f"buildfile_{filename}")
    return uuid, f'\t\t{uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};'


def main():
    print("🔧 Fixing Xcode project.pbxproj...")

    # Read current project file
    with open(PBXPROJ_PATH, 'r') as f:
        content = f.read()

    # Track all new entries
    new_file_refs = []
    new_build_files = []
    new_source_entries = []
    group_additions = {}

    # Process each file
    for filename, group_name, relative_path in FILES_TO_ADD:
        if filename in SKIP_FILES:
            print(f"⏭️  Skipping {filename} (already in project)")
            continue

        # Check if file exists
        file_path = os.path.join(KPOPVOTE_DIR, relative_path)
        if not os.path.exists(file_path):
            print(f"⚠️  File not found: {file_path}")
            continue

        print(f"✅ Adding {filename} to {group_name}")

        # Create file reference
        file_ref_uuid, file_ref_entry = create_file_reference(filename, relative_path)
        new_file_refs.append(file_ref_entry)

        # Create build file
        build_file_uuid, build_file_entry = create_build_file(filename, file_ref_uuid)
        new_build_files.append(build_file_entry)

        # Add to sources build phase
        new_source_entries.append(f'\t\t\t\t{build_file_uuid} /* {filename} in Sources */,')

        # Track group additions
        if group_name not in group_additions:
            group_additions[group_name] = []
        group_additions[group_name].append(f'\t\t\t\t{file_ref_uuid} /* {filename} */,')

    # Insert new PBXFileReference entries
    pbx_file_ref_end = content.find('/* End PBXFileReference section */')
    if pbx_file_ref_end != -1:
        insert_pos = content.rfind('\n', 0, pbx_file_ref_end) + 1
        content = content[:insert_pos] + '\n'.join(new_file_refs) + '\n' + content[insert_pos:]
        print(f"📝 Added {len(new_file_refs)} file references")

    # Insert new PBXBuildFile entries
    pbx_build_file_end = content.find('/* End PBXBuildFile section */')
    if pbx_build_file_end != -1:
        insert_pos = content.rfind('\n', 0, pbx_build_file_end) + 1
        content = content[:insert_pos] + '\n'.join(new_build_files) + '\n' + content[insert_pos:]
        print(f"📝 Added {len(new_build_files)} build file entries")

    # Add to PBXSourcesBuildPhase
    # Find the main target sources section (4FF2C7D92EC4102800186296)
    sources_section_match = re.search(
        r'(4FF2C7D92EC4102800186296 /\* Sources \*/ = \{[^\}]*files = \(\s*)(.*?)(\s*\);)',
        content,
        re.DOTALL
    )
    if sources_section_match:
        before = sources_section_match.group(1)
        existing = sources_section_match.group(2)
        after = sources_section_match.group(3)
        new_sources = '\n'.join(new_source_entries)
        replacement = before + existing.rstrip() + '\n' + new_sources + '\n' + after
        content = content[:sources_section_match.start()] + replacement + content[sources_section_match.end():]
        print(f"📝 Added {len(new_source_entries)} source file entries to build phase")

    # Create new PBXGroup entries for missing groups
    # Find the ViewModels group to use as reference point
    viewmodels_group_match = re.search(
        r'(4FA228922EC4607B00FCC66B /\* ViewModels \*/ = \{[^\}]*\};)',
        content,
        re.DOTALL
    )

    if viewmodels_group_match:
        insert_after_pos = viewmodels_group_match.end()

        # Create new groups
        new_groups_content = []

        # Services group
        if "Services" in group_additions:
            services_uuid = generate_uuid("group_Services")
            services_children = '\n'.join(group_additions["Services"])
            services_group = f'''
\t\t{services_uuid} /* Services */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{services_children}
\t\t\t);
\t\t\tpath = Services;
\t\t\tsourceTree = "<group>";
\t\t}};'''
            new_groups_content.append(services_group)

            # Add to main group
            main_group_match = re.search(
                r'(4FF2C7D42EC4102800186296 = \{[^\}]*children = \(\s*)(.*?)(\s*\);)',
                content,
                re.DOTALL
            )
            if main_group_match:
                before = main_group_match.group(1)
                children = main_group_match.group(2)
                after = main_group_match.group(3)
                new_children = children.rstrip() + f'\n\t\t\t\t{services_uuid} /* Services */,'
                content = content[:main_group_match.start()] + before + new_children + '\n' + after + content[main_group_match.end():]

        # Models group
        if "Models" in group_additions:
            models_uuid = generate_uuid("group_Models")
            models_children = '\n'.join(group_additions["Models"])
            models_group = f'''
\t\t{models_uuid} /* Models */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{models_children}
\t\t\t);
\t\t\tpath = Models;
\t\t\tsourceTree = "<group>";
\t\t}};'''
            new_groups_content.append(models_group)

            # Add to main group
            main_group_match = re.search(
                r'(4FF2C7D42EC4102800186296 = \{[^\}]*children = \(\s*)(.*?)(\s*\);)',
                content,
                re.DOTALL
            )
            if main_group_match:
                before = main_group_match.group(1)
                children = main_group_match.group(2)
                after = main_group_match.group(3)
                new_children = children.rstrip() + f'\n\t\t\t\t{models_uuid} /* Models */,'
                content = content[:main_group_match.start()] + before + new_children + '\n' + after + content[main_group_match.end():]

        # Insert new groups after ViewModels group
        if new_groups_content:
            content = content[:insert_after_pos] + ''.join(new_groups_content) + content[insert_after_pos:]
            print(f"📝 Created {len(new_groups_content)} new groups")

    # Write updated content
    with open(PBXPROJ_PATH, 'w') as f:
        f.write(content)

    print("\n✅ Successfully updated project.pbxproj!")
    print(f"📦 Added {len(new_file_refs)} files to the project")
    print("\n🔄 Next steps:")
    print("1. Open Xcode")
    print("2. Clean Build Folder (Product → Clean Build Folder)")
    print("3. Build & Run (⌘R)")


if __name__ == "__main__":
    main()
