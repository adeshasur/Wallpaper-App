import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// Firebase configuration using existing keys
const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDjffxaZJ7vmAlzA-LnN0Vhlh3EBJ4uRqE",
  authDomain: "wallpaper-incc.firebaseapp.com",
  projectId: "wallpaper-incc",
  storageBucket: "wallpaper-incc.appspot.com",
  messagingSenderId: "795698360511",
  appId: "1:795698360511:web:af7e54ac8e2f410a6ad60a",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const WallpaperApp());
}

class WallpaperApp extends StatelessWidget {
  const WallpaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper Inc.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFFFF6584),
          surface: Color(0xFF1E1E2F),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// Fallback Curated Categories using Unsplash links
final List<Map<String, String>> fallbackCategories = [
  {
    'id': 'nature',
    'name': 'Nature',
    'thumbnail': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=500&auto=format&fit=crop&q=60',
  },
  {
    'id': 'space',
    'name': 'Space',
    'thumbnail': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=500&auto=format&fit=crop&q=60',
  },
  {
    'id': 'cars',
    'name': 'Cars',
    'thumbnail': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=500&auto=format&fit=crop&q=60',
  },
  {
    'id': 'minimal',
    'name': 'Minimal',
    'thumbnail': 'https://images.unsplash.com/photo-1494438639946-1ebd1d2038b5?w=500&auto=format&fit=crop&q=60',
  },
];

// Fallback Curated Wallpapers per category
final Map<String, List<Map<String, String>>> fallbackWallpapersByCategory = {
  'nature': [
    {
      'title': 'Green Forests',
      'url': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Mountain Sunrise',
      'url': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Sea Waves',
      'url': 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=1080&auto=format&fit=crop&q=80',
    },
  ],
  'space': [
    {
      'title': 'Deep Nebula',
      'url': 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Spiral Galaxy',
      'url': 'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Blue Earth',
      'url': 'https://images.unsplash.com/photo-1614730321146-b6fa6a46bcb4?w=1080&auto=format&fit=crop&q=80',
    },
  ],
  'cars': [
    {
      'title': 'Retro Porsche',
      'url': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Neon Sportscar',
      'url': 'https://images.unsplash.com/photo-1525609004556-c46c7d6cf0a3?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Offroad Mustang',
      'url': 'https://images.unsplash.com/photo-1611245801311-66df9892c906?w=1080&auto=format&fit=crop&q=80',
    },
  ],
  'minimal': [
    {
      'title': 'Aesthetic Plant',
      'url': 'https://images.unsplash.com/photo-1494438639946-1ebd1d2038b5?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Warm Geometry',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1080&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Pastel Dunes',
      'url': 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?w=1080&auto=format&fit=crop&q=80',
    },
  ],
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _picsumWallpapers = [];
  bool _isLoadingPicsum = false;

  @override
  void initState() {
    super.initState();
    _fetchPicsumWallpapers();
  }

  // Fetch free trending images from Lorem Picsum API (No Key Required)
  Future<void> _fetchPicsumWallpapers() async {
    setState(() {
      _isLoadingPicsum = true;
    });
    try {
      final response = await http.get(Uri.parse('https://picsum.photos/v2/list?limit=30'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _picsumWallpapers = data.map<Map<String, dynamic>>((item) {
            final id = item['id'].toString();
            // Construct a higher-res mobile-sized link (1080x1920)
            return {
              'id': id,
              'title': 'Wallpaper by ${item['author']}',
              'url': 'https://picsum.photos/id/$id/1080/1920',
              'categoryId': 'picsum',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching picsum images: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPicsum = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wallpaper Inc.',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchPicsumWallpapers();
            },
            tooltip: 'Refresh API Wallpapers',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchPicsumWallpapers();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categories Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Categories',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('categories').snapshots(),
                builder: (context, snapshot) {
                  List<Map<String, dynamic>> categories = [];

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    // Load categories from database if they exist
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      categories.add({
                        'id': doc.id,
                        'name': data['name'] ?? 'No Name',
                        'thumbnail': data['thumbnail'] ?? '',
                      });
                    }
                  } else {
                    // Fallback to offline curated categories
                    categories = fallbackCategories;
                  }

                  return SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final name = cat['name'] ?? 'No Name';
                        final thumbnail = cat['thumbnail'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryDetailScreen(
                                  categoryId: cat['id']!,
                                  categoryName: name,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: thumbnail.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(thumbnail),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withAlpha(102),
                                        BlendMode.darken,
                                      ),
                                    )
                                  : null,
                              color: Colors.grey[800],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Wallpapers section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Text(
                  'Explore Wallpapers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('wallpapers').snapshots(),
                builder: (context, snapshot) {
                  List<Map<String, dynamic>> wallpapers = [];

                  // 1. Gather Firestore database wallpapers if they exist
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      wallpapers.add({
                        'id': doc.id,
                        'url': data['url'] ?? '',
                        'title': data['title'] ?? 'Wallpaper',
                      });
                    }
                  }

                  // 2. Add API/curated wallpapers if database has few or no entries
                  if (wallpapers.isEmpty) {
                    if (_isLoadingPicsum) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    wallpapers = _picsumWallpapers;
                  }

                  if (wallpapers.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text('No wallpapers found. Pull to refresh!'),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: wallpapers.length,
                    itemBuilder: (context, index) {
                      final wp = wallpapers[index];
                      final url = wp['url'] ?? '';
                      final title = wp['title'] ?? 'Wallpaper';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WallpaperViewScreen(
                                imageUrl: url,
                                title: title,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: url,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: Colors.grey[900],
                              child: url.isNotEmpty
                                  ? Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(
                                              child: Icon(Icons.broken_image, color: Colors.grey)),
                                    )
                                  : const Center(child: Icon(Icons.image)),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('wallpapers')
            .where('categoryId', isEqualTo: categoryId)
            .snapshots(),
        builder: (context, snapshot) {
          List<Map<String, dynamic>> wallpapers = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              wallpapers.add({
                'id': doc.id,
                'url': data['url'] ?? '',
                'title': data['title'] ?? 'Wallpaper',
              });
            }
          } else {
            // Fallback to local curated wallpapers for this category
            wallpapers = fallbackWallpapersByCategory[categoryId.toLowerCase()] ?? [];
          }

          if (wallpapers.isEmpty) {
            return const Center(child: Text('No wallpapers in this category.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: wallpapers.length,
            itemBuilder: (context, index) {
              final wp = wallpapers[index];
              final url = wp['url'] ?? '';
              final title = wp['title'] ?? 'Wallpaper';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WallpaperViewScreen(
                        imageUrl: url,
                        title: title,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: url,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.grey[900],
                      child: url.isNotEmpty
                          ? Image.network(
                              url,
                              fit: BoxFit.cover,
                            )
                          : const Center(child: Icon(Icons.image)),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WallpaperViewScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const WallpaperViewScreen({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  Future<void> _downloadImage(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading wallpaper...'),
          duration: Duration(seconds: 2),
        ),
      );

      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      // Save to temporary directory as a fallback
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/wallpaper_$timestamp.jpg');
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to app storage successfully! File: wallpaper_$timestamp.jpg'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _downloadImage(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Download Wallpaper'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
