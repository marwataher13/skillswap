import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CategoryList extends StatefulWidget {
  final List<String> categories;
  final ValueChanged<int>? onCategorySelected;
  final int initialSelectedIndex;

  const CategoryList({
    super.key,
    this.categories = const ['Creative', 'Tech', 'Lifestyle', 'Business'],
    this.onCategorySelected,
    this.initialSelectedIndex = 0,
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                if (widget.onCategorySelected != null) {
                  widget.onCategorySelected!(index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? AppShadows.subtle : null,
                ),
                child: Center(
                  child: Text(
                    widget.categories[index],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
