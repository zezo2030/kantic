import '../../domain/entities/submit_trip_request_input.dart';

class SubmitTripRequestModel {
  final String? note;

  const SubmitTripRequestModel({this.note});

  factory SubmitTripRequestModel.fromInput(SubmitTripRequestInput input) {
    return SubmitTripRequestModel(note: input.note);
  }

  Map<String, dynamic> toJson() {
    return {
      if (note != null) 'note': note,
    };
  }
}

