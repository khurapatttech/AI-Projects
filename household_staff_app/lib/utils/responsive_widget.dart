import 'package:flutter/material.dart';
import 'screen_size.dart';

/// A responsive widget that helps with consistent spacing and sizing
class ResponsiveWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? spacing;
  
  const ResponsiveWidget({
    Key? key,
    required this.child,
    this.padding,
    this.spacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? ScreenSize.getResponsivePadding(context),
      child: child,
    );
  }
}

/// A responsive container with proper overflow handling
class ResponsiveContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final BoxDecoration? decoration;
  final bool scrollable;
  final ScrollPhysics? physics;
  
  const ResponsiveContainer({
    Key? key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.scrollable = false,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding ?? ScreenSize.getResponsivePadding(context),
      margin: margin,
      color: color,
      decoration: decoration,
      child: child,
    );
    
    if (scrollable) {
      content = SingleChildScrollView(
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }
    
    return content;
  }
}

/// A responsive grid widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;
  
  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int columns;
    if (ScreenSize.isDesktop(context)) {
      columns = desktopColumns ?? 4;
    } else if (ScreenSize.isTablet(context)) {
      columns = tabletColumns ?? 3;
    } else {
      columns = mobileColumns ?? 2;
    }
    
    List<Widget> rows = [];
    for (int i = 0; i < children.length; i += columns) {
      List<Widget> rowChildren = [];
      for (int j = 0; j < columns; j++) {
        if (i + j < children.length) {
          rowChildren.add(Expanded(child: children[i + j]));
          if (j < columns - 1) {
            rowChildren.add(SizedBox(width: spacing));
          }
        } else {
          rowChildren.add(const Expanded(child: SizedBox()));
        }
      }
      rows.add(Row(children: rowChildren));
      if (i + columns < children.length) {
        rows.add(SizedBox(height: runSpacing));
      }
    }
    
    return Column(children: rows);
  }
}

/// A responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSize = ScreenSize.getResponsiveFontSize(
      context,
      mobile: mobileFontSize ?? 14.0,
      tablet: tabletFontSize ?? 16.0,
      desktop: desktopFontSize ?? 18.0,
    );
    
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }
}

/// A responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  final double? mobile;
  final double? tablet;
  final double? desktop;
  final bool vertical;
  
  const ResponsiveSpacing({
    Key? key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.vertical = true,
  }) : super(key: key);
  
  const ResponsiveSpacing.horizontal({
    Key? key,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : vertical = false, super(key: key);

  @override
  Widget build(BuildContext context) {
    final spacing = ScreenSize.getResponsiveSpacing(
      context,
      mobile: mobile ?? 8.0,
      tablet: tablet ?? 12.0,
      desktop: desktop ?? 16.0,
    );
    
    return SizedBox(
      height: vertical ? spacing : null,
      width: vertical ? null : spacing,
    );
  }
}