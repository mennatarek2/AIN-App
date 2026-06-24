import 'package:flutter_test/flutter_test.dart';

import 'package:ain_graduation_project/core/enums/community_enums.dart';
import 'package:ain_graduation_project/core/network/api_exception.dart';
import 'package:ain_graduation_project/features/community/models/community_search_result.dart';
import 'package:ain_graduation_project/features/community/models/join_request.dart';
import 'package:ain_graduation_project/features/community/models/member_detail.dart';
import 'package:ain_graduation_project/features/community/utils/community_helpers.dart';
import 'package:ain_graduation_project/features/sos/domain/sos_alert_model.dart';

void main() {
  group('CommunitySearchResult', () {
    test('parses join status and copyWith updates pending state', () {
      final result = CommunitySearchResult.fromJson({
        'id': 'c1',
        'name': 'حي النخيل',
        'communityType': 0,
        'memberCount': 12,
        'acceptsJoinRequests': true,
        'hasActiveInviteCode': false,
        'isAlreadyMember': false,
        'myJoinStatus': 'Rejected',
      });

      expect(result.myJoinStatus, JoinStatus.rejected);
      expect(
        result.copyWith(myJoinStatus: JoinStatus.pending).myJoinStatus,
        JoinStatus.pending,
      );
    });
  });

  group('JoinRequestDto', () {
    test('parses safely with invalid date fallback', () {
      final dto = JoinRequestDto.fromJson({
        'memberId': 'm1',
        'userId': 'u1',
        'userName': 'Ali',
        'requestedAt': 'not-a-date',
        'status': 'Pending',
      });

      expect(dto.userId, 'u1');
      expect(dto.status, JoinStatus.pending);
    });

    test('parses integer status from API', () {
      final dto = JoinRequestDto.fromJson({
        'memberId': 'aa8d56df-3ad2-46d1-b47b-13c9b1bde5ce',
        'userId': 'ec12049f-4f03-4b13-bc1c-798b54492f50',
        'userName': 'Menna',
        'profilePhotoUrl': 'uploads/UserPhotos/e8254d6f-104f-462f-a4ac-1a20d14b5bf2.jpeg',
        'requestedAt': '2026-06-23T18:33:08.0919823',
        'status': 0,
      });

      expect(dto.status, JoinStatus.pending);
      expect(dto.profilePhotoUrl, isNotNull);
    });
  });

  group('MemberDetailDto', () {
    test('parses role and join status', () {
      final dto = MemberDetailDto.fromJson({
        'userId': 'u1',
        'userName': 'Sara',
        'role': 'Admin',
        'joinStatus': 'Approved',
        'joinedAt': '2026-01-01T00:00:00Z',
      });

      expect(dto.role, CommunityRole.admin);
      expect(dto.isApproved, isTrue);
    });

    test('parses integer communityRole and memberStatus', () {
      final dto = MemberDetailDto.fromJson({
        'userId': 'u2',
        'userName': 'Omar',
        'communityRole': 2,
        'joinStatus': 1,
        'memberStatus': 1,
        'joinedAt': '2026-01-01T00:00:00Z',
      });

      expect(dto.role, CommunityRole.admin);
      expect(dto.joinStatus, JoinStatus.approved);
      expect(dto.memberStatus, MemberStatus.locationPending);
    });
  });

  group('SosAlertModel multi-community', () {
    test('uses affectedCommunityIds when present', () {
      final alert = SosAlertModel.fromApiJson({
        'id': 's1',
        'communityId': 'c1',
        'affectedCommunityIds': ['c1', 'c2', 'c3'],
        'latitude': 24.0,
        'longitude': 46.0,
        'severity': 0,
        'status': 0,
      });

      expect(alert.allAffectedCommunityIds, ['c1', 'c2', 'c3']);
    });

    test('falls back to communityId when list empty', () {
      final alert = SosAlertModel.fromApiJson({
        'id': 's1',
        'communityId': 'c1',
        'latitude': 24.0,
        'longitude': 46.0,
        'severity': 0,
        'status': 0,
      });

      expect(alert.allAffectedCommunityIds, ['c1']);
    });
  });

  group('communityApiUserMessage', () {
    test('prefers detail for cooldown 400 errors', () {
      final message = communityApiUserMessage(
        ApiException(
          'Bad Request',
          statusCode: 400,
          detail: 'You can request again after 2026-07-15.',
        ),
      );

      expect(message, contains('2026-07-15'));
    });

    test('maps 409 pending request', () {
      final message = communityApiUserMessage(
        ApiException('Conflict', statusCode: 409, detail: 'pending request'),
      );

      expect(message, contains('قيد المراجعة'));
    });
  });
}
