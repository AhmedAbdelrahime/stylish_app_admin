import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/home/logic/offer/cubit/offer_cubit.dart';
import 'package:hungry/pages/home/logic/offer/cubit/offer_state.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OffersSection extends StatefulWidget {
  const OffersSection({super.key});

  @override
  State<OffersSection> createState() => _OffersSectionState();
}

class _OffersSectionState extends State<OffersSection> {
  int indexoffer = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfferCubit, OfferState>(
      builder: (context, state) {
        if (state is OfferLoading) {
          return const SizedBox(
            height: 210,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is OfferError) {
          return SizedBox(
            height: 210,
            child: Center(
              child: Text(state.message, textAlign: TextAlign.center),
            ),
          );
        }

        if (state is OfferLoaded) {
          if (state.offers.isEmpty) {
            return const SizedBox(
              height: 210,
              child: Center(child: Text('No offers found')),
            );
          }

          if (indexoffer >= state.offers.length) {
            indexoffer = 0;
          }

          return Column(
            children: [
              CarouselSlider.builder(
                itemCount: state.offers.length,
                options: CarouselOptions(
                  scrollPhysics: const BouncingScrollPhysics(),
                  height: 188,
                  viewportFraction: 0.9,
                  enableInfiniteScroll: state.offers.length > 1,
                  autoPlay: state.offers.length > 1,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration: const Duration(milliseconds: 700),
                  autoPlayCurve: Curves.easeOutCubic,
                  onPageChanged: (index, reason) {
                    setState(() {
                      indexoffer = index;
                    });
                  },
                ),
                itemBuilder: (context, index, realIndex) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            state.offers[index].imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade300),
                          ),
                          // DecoratedBox(
                          //   decoration: BoxDecoration(
                          //     gradient: LinearGradient(
                          //       begin: Alignment.topCenter,
                          //       end: Alignment.bottomCenter,
                          //       colors: [
                          //         Colors.black.withValues(alpha: 0.04),
                          //         Colors.black.withValues(alpha: 0.36),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          // const Positioned(
                          //   left: 18,
                          //   right: 18,
                          //   bottom: 18,
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Text(
                          //         'Fresh deals for your next order',
                          //         style: TextStyle(
                          //           color: Colors.white,
                          //           fontSize: 18,
                          //           fontWeight: FontWeight.w700,
                          //         ),
                          //       ),
                          //       Gap(4),
                          //       Text(
                          //         'Curated offers that give the storefront a stronger first impression.',
                          //         style: TextStyle(
                          //           color: Colors.white70,
                          //           fontSize: 12,
                          //           height: 1.4,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Gap(10),
              AnimatedSmoothIndicator(
                activeIndex: indexoffer,
                count: state.offers.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 10,
                  dotWidth: 8,
                  expansionFactor: 3,
                  activeDotColor: AppColors.redColor,
                  dotColor: AppColors.grayColor.withValues(alpha: 0.4),
                ),
              ),
            ],
          );
        }

        return const SizedBox(
          height: 210,
          child: Center(child: Text('Loading offers...')),
        );
      },
    );
  }
}
