import 'package:flutter/material.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_cards.dart';

class HomeMaterialsStrip extends StatelessWidget {
  const HomeMaterialsStrip({super.key, required this.courses});
  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return CourseList(courses: courses);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < courses.length; index++) ...[
              if (index != 0) const SizedBox(width: 16),
              SizedBox(
                width: constraints.maxWidth.clamp(0.0, 340.0),
                child: CourseCard(course: courses[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
