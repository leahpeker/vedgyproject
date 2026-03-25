const validTokensJson = <String, dynamic>{
  'access': 'test-access-token-abc123',
  'refresh': 'test-refresh-token-xyz789',
};

const userJson = <String, dynamic>{
  'id': 'user-uuid-001',
  'email': 'test@example.com',
  'first_name': 'Test',
  'last_name': 'User',
};

const testListingJson = <String, dynamic>{
  'id': 'listing-uuid-001',
  'title': 'Cozy Vegan Room',
  'description': 'Nice place.',
  'city': 'New York',
  'borough': 'Brooklyn',
  'neighborhood': null,
  'price': 1200,
  'start_date': null,
  'end_date': null,
  'rental_type': 'sublet',
  'room_type': 'private_room',
  'vegan_household': 'fully_vegan',
  'furnished': 'furnished',
  'lister_relationship': 'owner',
  'seeking_roommate': false,
  'about_lister': null,
  'rental_requirements': null,
  'pet_policy': null,
  'include_phone': false,
  'phone_number': null,
  'status': 'active',
  'user': {'id': 'user-uuid-001', 'first_name': 'Test', 'last_name': 'User'},
  'photos': <dynamic>[],
  'created_at': '2026-01-01T00:00:00Z',
  'expires_at': null,
};

const paginatedListingsJson = <String, dynamic>{
  'items': [testListingJson],
  'count': 1,
  'page': 1,
  'page_size': 20,
};

const emptyDashboardJson = <String, dynamic>{
  'drafts': <dynamic>[],
  'payment_submitted': <dynamic>[],
  'active': <dynamic>[],
  'expired': <dynamic>[],
  'deactivated': <dynamic>[],
};
