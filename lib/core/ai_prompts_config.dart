class AIPromptsConfig {
  static const List<String> icebreakers = [
    'Ảnh đại diện của bạn trông rất bình yên, bạn có hay đi dã ngoại không?',
    'Cuối tuần của bạn thường diễn ra như thế nào?',
    'Bạn thích một buổi tối ấm áp ở nhà hay đi dạo phố hơn?',
    'Thể loại nhạc nào giúp bạn nạp năng lượng sau một ngày mệt mỏi?',
    'Nếu được chọn một địa điểm để đi trốn ngay lúc này, bạn sẽ chọn đi đâu?',
  ];

  static const List<String> deeperPrompts = [
    'Điều gì khiến bạn thấy thoải mái nhất khi ở bên một người?',
    'Điều gì làm bạn vui vẻ và tự hào nhất trong tuần này?',
    'Kỷ niệm đáng nhớ nhất thời thơ ấu của bạn là gì?',
    'Một ngày hoàn hảo đối với bạn sẽ trông như thế nào?',
  ];

  static const List<Map<String, String>> mockDateSuggestions = [
    {
      'name': 'The Hideout Cafe',
      'category': 'Cafe',
      'distance': '1.2km',
      'price': '\$\$',
      'vibe': 'Yên tĩnh',
      'description': 'Phù hợp với vibe của hai bạn',
      'image': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?q=80&w=600',
    },
    {
      'name': "Pizza 4P's",
      'category': 'Dinner',
      'distance': '3.5km',
      'price': '\$\$\$',
      'vibe': 'Lãng mạn',
      'description': 'Không gian lãng mạn',
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=600',
    },
    {
      'name': 'West Lake Sunset',
      'category': 'Outdoor',
      'distance': '5.0km',
      'price': 'Free',
      'vibe': 'Dạo bộ',
      'description': 'Thư giãn cuối tuần',
      'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600',
    },
  ];
}
