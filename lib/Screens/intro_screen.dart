import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import 'login_screen.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onIntroComplete;

  const IntroScreen({super.key, required this.onIntroComplete});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroPageData> _introPages = [
    IntroPageData(
      imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=1674&auto=format&fit=crop',
      title: 'Welcome to Jam Beauty Lounge',
      description: 'Experience premium beauty & wellness services in a luxurious environment.',
      color: Color(0xFFFDF6E9),
    ),
    IntroPageData(
      imageUrl: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?q=80&w=1669&auto=format&fit=crop',
      title: 'Ready to Begin?',
      description: 'Join thousands of satisfied customers in their beauty journey.',
      color: Color(0xFFEFE4D6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-advance pages every 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (_currentPage < _introPages.length - 1 && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _skipIntro() async {
    // Mark intro as seen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);

    // Call completion callback
    widget.onIntroComplete();
    Get.offAll(() => const LoginScreen());
  }

  void _completeIntro() async {
    // Mark intro as seen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);

    // Call completion callback
    widget.onIntroComplete();
    Get.offAll(() => const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(360, 800));

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _introPages[_currentPage].color,
                  Colors.white,
                ],
              ),
            ),
          ),

          // PageView for intro slides
          PageView.builder(
            controller: _pageController,
            itemCount: _introPages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(_introPages[index]);
            },
          ),

          // Skip Button (top right)
          Positioned(
            top: 50.h,
            right: 20.w,
            child: _currentPage < _introPages.length - 1
                ? GestureDetector(
              onTap: _skipIntro,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
                : const SizedBox(),
          ),

          // Page Indicator (bottom center)
          Positioned(
            bottom: 140.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _introPages.length,
                    (index) => _buildPageIndicator(index),
              ),
            ),
          ),

          // Next/Get Started Button (bottom)
          Positioned(
            bottom: 60.h,
            left: 40.w,
            right: 40.w,
            child: _currentPage < _introPages.length - 1
                ? _buildNextButton()
                : _buildGetStartedButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(IntroPageData page) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 80.h),

            // Salon Image
            Container(
              width: 280.w,
              height: 280.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20.r,
                    spreadRadius: 2.r,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  width: 2.w,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: Image.network(
                  page.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primaryGold,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      child: Icon(
                        Icons.spa,
                        size: 80.w,
                        color: AppColors.primaryGold,
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 30.h),

            // App Name
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDecorativeLine(),
                    SizedBox(width: 15.w),
                    Text(
                      'Jam Beauty',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    _buildDecorativeLine(),
                  ],
                ),
                Text(
                  'L O U N G E',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryGold,
                    letterSpacing: 6.w,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Page Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                height: 1.3,
              ),
            ),

            SizedBox(height: 10.h),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                page.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeLine() {
    return Container(
      width: 40.w,
      height: 2.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.primaryGold,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeIcon(IconData icon) {
    return Container(
      width: 36.w,
      height: 36.h,
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Icon(
        icon,
        size: 20.w,
        color: AppColors.primaryGold,
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: _currentPage == index ? 30.w : 10.w,
      height: 10.h,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primaryGold
            : AppColors.primaryGold.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5.r),
        boxShadow: _currentPage == index
            ? [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.5),
            blurRadius: 8.r,
            spreadRadius: 1.r,
          ),
        ]
            : [],
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        if (_currentPage < _introPages.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 56.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        elevation: 5,
        shadowColor: AppColors.primaryGold.withOpacity(0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Next',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 10.w),
          Icon(
            Icons.arrow_forward_rounded,
            size: 20.w,
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return ElevatedButton(
      onPressed: _completeIntro,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 56.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get Started',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 10.w),
          Icon(
            Icons.rocket_launch_rounded,
            size: 20.w,
          ),
        ],
      ),
    );
  }
}

class IntroPageData {
  final String imageUrl;
  final String title;
  final String description;
  final Color color;

  IntroPageData({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.color,
  });
}