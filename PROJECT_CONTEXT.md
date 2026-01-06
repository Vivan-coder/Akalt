AKALT — FULL PRODUCT PLAN & FEATURE OVERVIEW
“Discover food through short, real videos.”
1️⃣ PRODUCT OVERVIEW
AKALT is a short-form vertical video food discovery platform that helps users:

Discover what to eat
See real food, not stock images
Decide faster
Order from their preferred platform
Restaurants use AKALT to:

Showcase menu items through video
Run offers
Gain visibility without ads fatigue
Track engagement and intent
2️⃣ USER TYPES & ROLES
👤 1. Regular User (Food Explorer)
Watches food videos
Uploads reviews
Likes, saves, comments
Clicks “Order”
🏪 2. Restaurant Account (Business)
Uploads official menu videos
Manages profile & menu
Views analytics
Promotes items
🛠️ 3. Admin (You)
Moderation
Feature toggles
Content approvals (optional)
System health
3️⃣ APP PLATFORM
Mobile App: Flutter (Android first, iOS later)
Restaurant Dashboard: Web app (Flutter Web or React)
Backend: Firebase
Video Hosting: Cloudflare Stream (later)
Maps: Google Maps SDK
4️⃣ CORE APP FEATURES (DETAILED)
🧱 A. AUTHENTICATION & ONBOARDING
Screens:
Splash Screen
Login
Signup
Forgot Password
Role Selection (User / Restaurant)
Features:
Email + Password login
Google Sign-In
User role saved in Firestore
Optional phone OTP (future)
Data Stored:

userId
username
email
role (user / restaurant)
location
favoriteTags
createdAt
🏠 B. HOME FEED (CORE EXPERIENCE)
What it is:
TikTok-style vertical swipe feed
Autoplay videos
Sound on/off
Infinite scrolling
Interactions:
❤️ Like
💬 Comment
🔖 Save
🛒 Order
➕ Follow restaurant
🧠 FEED ALGORITHM (FeedScore)
Each video gets a FeedScore, calculated by:

Factors:
Likes
Comments
Shares
Saves
Order clicks
Watch time
Upload freshness
Location proximity
Tag relevance
Creator credibility (restaurant vs user)
Result:
Higher score = shown to more users
New videos get temporary boost
Personalized feed per user
🎥 C. VIDEO SYSTEM
Video Types:
Restaurant Menu Video
User Review Video
Offer / Promotion Video
Video Metadata:

videoId
restaurantId
uploaderId
tags
location
avgWatchTime
likes
comments
orderClicks
createdAt
Upload Flow:
Select video
Add dish name
Add price (optional)
Select tags
Select restaurant (for users)
Upload
🏪 D. RESTAURANT PROFILES
Public View:
Restaurant info
Location
Menu videos
Reviews
Order buttons
Order Buttons:
Talabat
WhatsApp
Instagram
Website
⚠️ AKALT does NOT process payments (MVP)
🌐 E. RESTAURANT DASHBOARD (WEB)
Why Web?
Easier uploads
Analytics clarity
Business users prefer desktop
Features:
Upload videos
Manage menu items
Edit profile
View analytics
Analytics Shown:
Views
Likes
Saves
Order button clicks
Top dishes
Video performance
🔍 F. SEARCH & DISCOVERY
Search By:
Restaurant name
Dish name
Tags
Cuisine
Area
Explore Map:
Google Map
Restaurant pins
Tap → view videos
Filter by distance
🗺️ G. LOCATION FEATURES
Ask permission on first launch
Used for:
Feed relevance
Nearby restaurants
Map discovery
⭐ H. ENGAGEMENT SYSTEM
User Engagement:
Likes
Comments
Saves
Follows
Rewards (UI only initially):
Watch videos → earn points
Save videos → earn points
Wallet screen (future monetization)
🔔 I. NOTIFICATIONS
New restaurant videos
Offers near you
Comment replies
Followed restaurant uploads
👤 J. USER PROFILE
Shows:
Username
Avatar
Saved videos
Liked videos
Upload history
🔐 K. SECURITY & MODERATION
Firebase Security Rules
Role-based access
Report video
Admin delete/block
💰 L. MONETIZATION
Phase 1:
Restaurant subscription (25 BHD/month)
Phase 2:
Featured placements
Boosted videos
Sponsored content
Phase 3:
Affiliate commissions
Data insights (anonymized)
🚀 M. LAUNCH STRATEGY
Pre-Launch:
Website + survey
Instagram page
Restaurant onboarding
Beta users
Launch:
Android first
Campus + food influencers
QR posters
🧪 N. TESTING & VALIDATION
Mock data testing
Firebase emulator
Internal beta
Analytics verification
📈 O. METRICS TO TRACK
User Metrics:
DAU / MAU
Session time
Video completion
Restaurant Metrics:
Order clicks
Video engagement
Retention
🧩 P. TECH STACK SUMMARY
LayerToolFrontendFlutterBackendFirebaseAuthFirebase AuthDBFirestoreStorageFirebase / CloudflareMapsGoogle MapsCI/CDCodemagic
🏁 FINAL NOTE (IMPORTANT)
AKALT is not just an app:

It’s content
It’s intent
It’s discovery
You’re building infrastructure for local food commerce, not just videos.
this is the plan for now but we can make changes with the tools if wanted ti make it better'