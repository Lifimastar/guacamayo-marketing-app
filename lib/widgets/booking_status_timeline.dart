import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../utils/booking_status_utils.dart';

class BookingStatusTimeline extends StatelessWidget {
  final String currentStatus;
  final List<String> allStatuses;
  const BookingStatusTimeline({
    super.key,
    required this.currentStatus,
    required this.allStatuses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = allStatuses.indexOf(currentStatus);
    return Column(
      children: List.generate(allStatuses.length, (index) {
        final status = allStatuses[index];
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;
        final isFirst = index == 0;
        final isLast = index == allStatuses.length - 1;

        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          isFirst: isFirst,
          isLast: isLast,
          // Indicador (el circulo)
          indicatorStyle: IndicatorStyle(
            width: 30,
            height: 30,
            indicator: Container(
              decoration: BoxDecoration(
                color:
                    isCompleted || isCurrent
                        ? BookingStatusUtils.getStatusColor(status)
                        : Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isCurrent
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                  width: isCurrent ? 3.0 : 0,
                ),
              ),
              child: Center(
                child:
                    isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : isCurrent
                        ? const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
          ),
          // Lineas antes y despues del indicador
          beforeLineStyle: LineStyle(
            color:
                isCompleted || isCurrent
                    ? BookingStatusUtils.getStatusColor(status)
                    : Colors.grey[300]!,
            thickness: 4,
          ),
          afterLineStyle: LineStyle(
            color:
                isCompleted
                    ? BookingStatusUtils.getStatusColor(status)
                    : Colors.grey[300]!,
            thickness: 4,
          ),
          // Contenido a la derecha del timeline
          endChild: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BookingStatusUtils.getStatusText(status),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color:
                        isCompleted || isCurrent
                            ? theme.colorScheme.onSurface
                            : Colors.grey,
                  ),
                ),
                // Opcional: Anadir fecha de actualizacion de estado si la guardas en la DB
              ],
            ),
          ),
        );
      }),
    );
  }
}
