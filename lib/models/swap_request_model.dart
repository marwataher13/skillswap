class SwapRequestUser {
  final int id;
  final String name;
  final String? email;
  final String? profilePicture;
  final String? trustScore;
 
  const SwapRequestUser({
    required this.id,
    required this.name,
    this.email,
    this.profilePicture,
    this.trustScore,
  });
 
  factory SwapRequestUser.fromJson(Map<String, dynamic> json) {
    return SwapRequestUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      profilePicture: json['profile_picture'] as String?,
      trustScore: json['trust_score']?.toString(),
    );
  }
}
 
class SwapRequest {
  final int id;
  final int senderId;
  final int receiverId;
  final String? message;
  final String status; // pending | accepted | rejected | cancelled
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SwapRequestUser? sender;
  final SwapRequestUser? receiver;
 
  const SwapRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.message,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
  });
 
  factory SwapRequest.fromJson(Map<String, dynamic> json) {
    return SwapRequest(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      sender: json['sender'] != null
          ? SwapRequestUser.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      receiver: json['receiver'] != null
          ? SwapRequestUser.fromJson(json['receiver'] as Map<String, dynamic>)
          : null,
    );
  }
 
  SwapRequest copyWith({String? status}) {
    return SwapRequest(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sender: sender,
      receiver: receiver,
    );
  }
}