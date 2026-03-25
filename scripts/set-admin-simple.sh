#!/bin/bash

# Simple script to set admin role using Firebase CLI
# Usage: ./scripts/set-admin-simple.sh <email>

EMAIL=$1

if [ -z "$EMAIL" ]; then
  echo "Usage: ./scripts/set-admin-simple.sh <email>"
  exit 1
fi

echo "Setting admin role for: $EMAIL"
echo ""
echo "Please follow these steps:"
echo ""
echo "1. Get the user UID from Firebase Console:"
echo "   https://console.firebase.google.com/project/kpopvote-9de2b/authentication/users"
echo ""
echo "2. Find the user with email: $EMAIL"
echo "3. Copy the UID (long string like: abc123def456...)"
echo ""
echo "4. Run this command with the UID:"
echo ""
echo "   firebase functions:shell"
echo ""
echo "5. In the shell, run:"
echo ""
echo "   setAdmin({data: {uid: 'PASTE_UID_HERE'}})"
echo ""
echo "6. Press Ctrl+C to exit the shell"
echo ""
echo "7. Have the user sign out and sign in again"
