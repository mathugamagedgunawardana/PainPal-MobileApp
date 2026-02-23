import 'dart:convert';

class MigraineAttack {
  MigraineAttack({
    required this.durationHours,
    required this.frequencyPerMonth,
    required this.location,
    required this.character,
    required this.intensity,
    required this.nausea,
    required this.vomit,
    required this.phonophobia,
    required this.photophobia,
    required this.visual,
    required this.sensory,
    required this.dysphasia,
    required this.dysarthria,
    required this.vertigo,
    required this.tinnitus,
    required this.hypoacusis,
    required this.diplopia,
    required this.defect,
    required this.ataxia,
    required this.conscience,
    required this.paresthesia,
    required this.dpf,
    this.type,
    this.patientId,
    this.attackId,
    this.age,
    this.timestamp,
    this.summary,
  });

  final int durationHours;
  final int frequencyPerMonth;
  final String location;
  final String character;
  final int intensity;
  final int nausea;
  final int vomit;
  final int phonophobia;
  final int photophobia;
  final int visual;
  final int sensory;
  final int dysphasia;
  final int dysarthria;
  final int vertigo;
  final int tinnitus;
  final int hypoacusis;
  final int diplopia;
  final int defect;
  final int ataxia;
  final int conscience;
  final int paresthesia;
  final String dpf;
  final String? type;
  final String? patientId;
  final String? attackId;
  final int? age;
  final DateTime? timestamp;
  final String? summary;

  Map<String, dynamic> toApiJson() {
    final payload = <String, dynamic>{
      'Duration': durationHours,
      'Frequency': frequencyPerMonth,
      'Location': location,
      'Character': character,
      'Intensity': intensity,
      'Nausea': nausea,
      'Vomit': vomit,
      'Phonophobia': phonophobia,
      'Photophobia': photophobia,
      'Visual': visual,
      'Sensory': sensory,
      'Dysphasia': dysphasia,
      'Dysarthria': dysarthria,
      'Vertigo': vertigo,
      'Tinnitus': tinnitus,
      'Hypoacusis': hypoacusis,
      'Diplopia': diplopia,
      'Defect': defect,
      'Ataxia': ataxia,
      'Conscience': conscience,
      'Paresthesia': paresthesia,
      'DPF': dpf,
    };

    if (patientId != null && patientId!.isNotEmpty) {
      payload['patient_id'] = patientId;
    }
    if (attackId != null && attackId!.isNotEmpty) {
      payload['attack_id'] = attackId;
    }
    if (age != null) {
      payload['age'] = age;
    }
    if (timestamp != null) {
      payload['timestamp'] = timestamp!.toIso8601String();
    }

    return payload;
  }

  Map<String, dynamic> toDbMap() {
    return {
      'patient_id': patientId,
      'attack_id': attackId,
      'Duration': durationHours,
      'Frequency': frequencyPerMonth,
      'Location': location,
      'Character': character,
      'Intensity': intensity,
      'Nausea': nausea,
      'Vomit': vomit,
      'Phonophobia': phonophobia,
      'Photophobia': photophobia,
      'Visual': visual,
      'Sensory': sensory,
      'Dysphasia': dysphasia,
      'Dysarthria': dysarthria,
      'Vertigo': vertigo,
      'Tinnitus': tinnitus,
      'Hypoacusis': hypoacusis,
      'Diplopia': diplopia,
      'Defect': defect,
      'Ataxia': ataxia,
      'Conscience': conscience,
      'Paresthesia': paresthesia,
      'DPF': dpf,
      'Type': type,
      'summary': summary,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    };
  }

  static MigraineAttack fromDb(Map<String, Object?> map) {
    return MigraineAttack(
      durationHours: (map['Duration'] as int?) ?? 0,
      frequencyPerMonth: (map['Frequency'] as int?) ?? 0,
      location: (map['Location'] as String?) ?? '',
      character: (map['Character'] as String?) ?? '',
      intensity: (map['Intensity'] as int?) ?? 0,
      nausea: (map['Nausea'] as int?) ?? 0,
      vomit: (map['Vomit'] as int?) ?? 0,
      phonophobia: (map['Phonophobia'] as int?) ?? 0,
      photophobia: (map['Photophobia'] as int?) ?? 0,
      visual: (map['Visual'] as int?) ?? 0,
      sensory: (map['Sensory'] as int?) ?? 0,
      dysphasia: (map['Dysphasia'] as int?) ?? 0,
      dysarthria: (map['Dysarthria'] as int?) ?? 0,
      vertigo: (map['Vertigo'] as int?) ?? 0,
      tinnitus: (map['Tinnitus'] as int?) ?? 0,
      hypoacusis: (map['Hypoacusis'] as int?) ?? 0,
      diplopia: (map['Diplopia'] as int?) ?? 0,
      defect: (map['Defect'] as int?) ?? 0,
      ataxia: (map['Ataxia'] as int?) ?? 0,
      conscience: (map['Conscience'] as int?) ?? 0,
      paresthesia: (map['Paresthesia'] as int?) ?? 0,
      dpf: (map['DPF'] as String?) ?? '',
      type: map['Type'] as String?,
      patientId: map['patient_id'] as String?,
      attackId: map['attack_id'] as String?,
      age: map['age'] as int?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
      summary: map['summary'] as String?,
    );
  }

  String toDraftJson() => jsonEncode(toDbMap());

  static MigraineAttack? fromDraftJson(String? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    final map = jsonDecode(json) as Map<String, dynamic>;
    return MigraineAttack.fromDb(map);
  }
}

class MigraineApiResponse {
  MigraineApiResponse({
    required this.summary,
    required this.predictedType,
    required this.symptomsReceived,
  });

  final String summary;
  final String predictedType;
  final List<String> symptomsReceived;

  static MigraineApiResponse fromJson(Map<String, dynamic> json) {
    return MigraineApiResponse(
      summary: json['summary'] as String? ?? '',
      predictedType: json['predicted_migraine_type'] as String? ?? 'Unknown',
      symptomsReceived: (json['symptoms_received'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
    );
  }
}

class MriScan {
  MriScan({
    required this.imagePath,
    required this.prediction,
    required this.confidence,
    required this.timestamp,
    this.patientId,
    this.mriId,
  });

  final String imagePath;
  final String prediction;
  final double? confidence;
  final DateTime timestamp;
  final String? patientId;
  final String? mriId;

  Map<String, dynamic> toDbMap() {
    return {
      'patient_id': patientId,
      'mri_id': mriId,
      'image_path': imagePath,
      'prediction': prediction,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static MriScan fromDb(Map<String, Object?> map) {
    return MriScan(
      imagePath: (map['image_path'] as String?) ?? '',
      prediction: (map['prediction'] as String?) ?? 'Pending',
      confidence: map['confidence'] as double?,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      patientId: map['patient_id'] as String?,
      mriId: map['mri_id'] as String?,
    );
  }
}

class MriApiResponse {
  MriApiResponse({
    required this.prediction,
    required this.confidence,
  });

  final String prediction;
  final double confidence;

  static MriApiResponse fromJson(Map<String, dynamic> json) {
    return MriApiResponse(
      prediction: json['prediction'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

extension MigraineAttackCopy on MigraineAttack {
  MigraineAttack copyWith({String? patientId}) {
    return MigraineAttack(
      durationHours: durationHours,
      frequencyPerMonth: frequencyPerMonth,
      location: location,
      character: character,
      intensity: intensity,
      nausea: nausea,
      vomit: vomit,
      phonophobia: phonophobia,
      photophobia: photophobia,
      visual: visual,
      sensory: sensory,
      dysphasia: dysphasia,
      dysarthria: dysarthria,
      vertigo: vertigo,
      tinnitus: tinnitus,
      hypoacusis: hypoacusis,
      diplopia: diplopia,
      defect: defect,
      ataxia: ataxia,
      conscience: conscience,
      paresthesia: paresthesia,
      dpf: dpf,
      type: type,
      patientId: patientId ?? this.patientId,
      attackId: attackId,
      age: age,
      timestamp: timestamp,
      summary: summary,
    );
  }
}
