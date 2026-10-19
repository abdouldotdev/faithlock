import 'package:faithlock/config/logger.dart';
import 'package:faithlock/features/prayer_audio/data/prayer_repository.dart';
import 'package:faithlock/features/prayer_audio/models/prayer.dart';
import 'package:get/get.dart';

/// GetX controller that loads and organises prayers by domain.
class PrayerLibraryController extends GetxController {
  PrayerLibraryController({PrayerRepository? repository})
      : _repository = repository ?? PrayerRepository();

  final PrayerRepository _repository;

  // ── Reactive state ─────────────────────────────────────────────────────────

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxList<Prayer> prayers = <Prayer>[].obs;

  /// Prayers grouped by domain, in a defined display order.
  final RxMap<PrayerDomain, List<Prayer>> grouped =
      <PrayerDomain, List<Prayer>>{}.obs;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadPrayers();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> loadPrayers() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _repository.fetchPrayers();
      prayers.assignAll(result);
      _groupByDomain(result);
    } catch (e) {
      logger.error('[PrayerLibraryController] fetchPrayers error: $e');
      errorMessage.value = 'Could not load prayers. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// The featured / recommended prayer for today.
  ///
  /// Currently returns the first prayer in the list. In a future iteration
  /// this could be server-driven or based on time-of-day / user history.
  Prayer? get featuredPrayer => prayers.isNotEmpty ? prayers.first : null;

  // ── Private ────────────────────────────────────────────────────────────────

  void _groupByDomain(List<Prayer> list) {
    final map = <PrayerDomain, List<Prayer>>{};
    // Maintain a fixed display order for domains.
    for (final domain in PrayerDomain.values) {
      final domainPrayers = list
          .where((p) => p.domain == domain)
          .toList();
      if (domainPrayers.isNotEmpty) {
        map[domain] = domainPrayers;
      }
    }
    grouped.assignAll(map);
  }
}
