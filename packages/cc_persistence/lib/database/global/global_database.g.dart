// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_database.dart';

// ignore_for_file: type=lint
class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, UsersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handleMeta = const VerificationMeta('handle');
  @override
  late final GeneratedColumn<String> handle = GeneratedColumn<String>(
    'handle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailVerifiedMeta = const VerificationMeta(
    'emailVerified',
  );
  @override
  late final GeneratedColumn<bool> emailVerified = GeneratedColumn<bool>(
    'email_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("email_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _avatarRefMeta = const VerificationMeta(
    'avatarRef',
  );
  @override
  late final GeneratedColumn<String> avatarRef = GeneratedColumn<String>(
    'avatar_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gitAuthorNameMeta = const VerificationMeta(
    'gitAuthorName',
  );
  @override
  late final GeneratedColumn<String> gitAuthorName = GeneratedColumn<String>(
    'git_author_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gitAuthorEmailMeta = const VerificationMeta(
    'gitAuthorEmail',
  );
  @override
  late final GeneratedColumn<String> gitAuthorEmail = GeneratedColumn<String>(
    'git_author_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ssoSubjectMeta = const VerificationMeta(
    'ssoSubject',
  );
  @override
  late final GeneratedColumn<String> ssoSubject = GeneratedColumn<String>(
    'sso_subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ssoIssuerMeta = const VerificationMeta(
    'ssoIssuer',
  );
  @override
  late final GeneratedColumn<String> ssoIssuer = GeneratedColumn<String>(
    'sso_issuer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deactivatedAtMeta = const VerificationMeta(
    'deactivatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deactivatedAt =
      GeneratedColumn<DateTime>(
        'deactivated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _onboardingFinishedAtMeta =
      const VerificationMeta('onboardingFinishedAt');
  @override
  late final GeneratedColumn<DateTime> onboardingFinishedAt =
      GeneratedColumn<DateTime>(
        'onboarding_finished_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    handle,
    displayName,
    email,
    emailVerified,
    avatarRef,
    gitAuthorName,
    gitAuthorEmail,
    ssoSubject,
    ssoIssuer,
    deactivatedAt,
    onboardingFinishedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('handle')) {
      context.handle(
        _handleMeta,
        handle.isAcceptableOrUnknown(data['handle']!, _handleMeta),
      );
    } else if (isInserting) {
      context.missing(_handleMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('email_verified')) {
      context.handle(
        _emailVerifiedMeta,
        emailVerified.isAcceptableOrUnknown(
          data['email_verified']!,
          _emailVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('avatar_ref')) {
      context.handle(
        _avatarRefMeta,
        avatarRef.isAcceptableOrUnknown(data['avatar_ref']!, _avatarRefMeta),
      );
    }
    if (data.containsKey('git_author_name')) {
      context.handle(
        _gitAuthorNameMeta,
        gitAuthorName.isAcceptableOrUnknown(
          data['git_author_name']!,
          _gitAuthorNameMeta,
        ),
      );
    }
    if (data.containsKey('git_author_email')) {
      context.handle(
        _gitAuthorEmailMeta,
        gitAuthorEmail.isAcceptableOrUnknown(
          data['git_author_email']!,
          _gitAuthorEmailMeta,
        ),
      );
    }
    if (data.containsKey('sso_subject')) {
      context.handle(
        _ssoSubjectMeta,
        ssoSubject.isAcceptableOrUnknown(data['sso_subject']!, _ssoSubjectMeta),
      );
    }
    if (data.containsKey('sso_issuer')) {
      context.handle(
        _ssoIssuerMeta,
        ssoIssuer.isAcceptableOrUnknown(data['sso_issuer']!, _ssoIssuerMeta),
      );
    }
    if (data.containsKey('deactivated_at')) {
      context.handle(
        _deactivatedAtMeta,
        deactivatedAt.isAcceptableOrUnknown(
          data['deactivated_at']!,
          _deactivatedAtMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_finished_at')) {
      context.handle(
        _onboardingFinishedAtMeta,
        onboardingFinishedAt.isAcceptableOrUnknown(
          data['onboarding_finished_at']!,
          _onboardingFinishedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      handle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handle'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      emailVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}email_verified'],
      )!,
      avatarRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_ref'],
      ),
      gitAuthorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}git_author_name'],
      ),
      gitAuthorEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}git_author_email'],
      ),
      ssoSubject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sso_subject'],
      ),
      ssoIssuer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sso_issuer'],
      ),
      deactivatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deactivated_at'],
      ),
      onboardingFinishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}onboarding_finished_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTableTable createAlias(String alias) {
    return $UsersTableTable(attachedDatabase, alias);
  }
}

class UsersTableData extends DataClass implements Insertable<UsersTableData> {
  /// Unique user identifier.
  final String id;

  /// Unique short handle (mention name).
  final String handle;

  /// Display name shown across the UI.
  final String displayName;

  /// Optional email address (invites work without one).
  final String? email;

  /// Whether [email] was vouched for by the identity provider (SSO, SCIM) or
  /// the server owner. Only a vouched address matches an SSO login or a SCIM
  /// push; one a person typed about themselves never does.
  final bool emailVerified;

  /// Optional avatar reference (server media ref or remote URL).
  final String? avatarRef;

  /// Git author name for commits made on this user's behalf.
  final String? gitAuthorName;

  /// Git author email for commits made on this user's behalf.
  final String? gitAuthorEmail;

  /// The SSO provider's immutable subject id (SAML NameID / SCIM externalId)
  /// when the user arrived via SSO/SCIM. Pinned with [ssoIssuer] so a later
  /// email change at the provider cannot silently take over the account.
  final String? ssoSubject;

  /// The issuer whose [ssoSubject] this is (IdP entity id or SCIM
  /// namespace).
  final String? ssoIssuer;

  /// When SCIM deprovisioning disabled the account (null = active). A
  /// deactivated user keeps their row (attribution is permanent) but cannot
  /// log in, holds no devices and belongs to no workspace.
  final DateTime? deactivatedAt;

  /// When this user finished first-run setup (null = never has).
  ///
  /// A column on the IDENTITY rather than a row in `user_preferences`, because the preference
  /// lane carries a one-time promotion pass that seeds the server from whatever the first
  /// device happens to hold locally.
  /// This flag used to ride that lane, and a stale device-local `true` was promoted onto a
  /// brand-new account: the onboarding gate then read "has been set up before", so a person
  /// who had never onboarded was sent to the re-auth screen — which offers a sign-in and none
  /// of the setup they actually needed.
  final DateTime? onboardingFinishedAt;

  /// When the user was provisioned.
  final DateTime createdAt;
  const UsersTableData({
    required this.id,
    required this.handle,
    required this.displayName,
    this.email,
    required this.emailVerified,
    this.avatarRef,
    this.gitAuthorName,
    this.gitAuthorEmail,
    this.ssoSubject,
    this.ssoIssuer,
    this.deactivatedAt,
    this.onboardingFinishedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['handle'] = Variable<String>(handle);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['email_verified'] = Variable<bool>(emailVerified);
    if (!nullToAbsent || avatarRef != null) {
      map['avatar_ref'] = Variable<String>(avatarRef);
    }
    if (!nullToAbsent || gitAuthorName != null) {
      map['git_author_name'] = Variable<String>(gitAuthorName);
    }
    if (!nullToAbsent || gitAuthorEmail != null) {
      map['git_author_email'] = Variable<String>(gitAuthorEmail);
    }
    if (!nullToAbsent || ssoSubject != null) {
      map['sso_subject'] = Variable<String>(ssoSubject);
    }
    if (!nullToAbsent || ssoIssuer != null) {
      map['sso_issuer'] = Variable<String>(ssoIssuer);
    }
    if (!nullToAbsent || deactivatedAt != null) {
      map['deactivated_at'] = Variable<DateTime>(deactivatedAt);
    }
    if (!nullToAbsent || onboardingFinishedAt != null) {
      map['onboarding_finished_at'] = Variable<DateTime>(onboardingFinishedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersTableCompanion toCompanion(bool nullToAbsent) {
    return UsersTableCompanion(
      id: Value(id),
      handle: Value(handle),
      displayName: Value(displayName),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      emailVerified: Value(emailVerified),
      avatarRef: avatarRef == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarRef),
      gitAuthorName: gitAuthorName == null && nullToAbsent
          ? const Value.absent()
          : Value(gitAuthorName),
      gitAuthorEmail: gitAuthorEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(gitAuthorEmail),
      ssoSubject: ssoSubject == null && nullToAbsent
          ? const Value.absent()
          : Value(ssoSubject),
      ssoIssuer: ssoIssuer == null && nullToAbsent
          ? const Value.absent()
          : Value(ssoIssuer),
      deactivatedAt: deactivatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deactivatedAt),
      onboardingFinishedAt: onboardingFinishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(onboardingFinishedAt),
      createdAt: Value(createdAt),
    );
  }

  factory UsersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsersTableData(
      id: serializer.fromJson<String>(json['id']),
      handle: serializer.fromJson<String>(json['handle']),
      displayName: serializer.fromJson<String>(json['displayName']),
      email: serializer.fromJson<String?>(json['email']),
      emailVerified: serializer.fromJson<bool>(json['emailVerified']),
      avatarRef: serializer.fromJson<String?>(json['avatarRef']),
      gitAuthorName: serializer.fromJson<String?>(json['gitAuthorName']),
      gitAuthorEmail: serializer.fromJson<String?>(json['gitAuthorEmail']),
      ssoSubject: serializer.fromJson<String?>(json['ssoSubject']),
      ssoIssuer: serializer.fromJson<String?>(json['ssoIssuer']),
      deactivatedAt: serializer.fromJson<DateTime?>(json['deactivatedAt']),
      onboardingFinishedAt: serializer.fromJson<DateTime?>(
        json['onboardingFinishedAt'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'handle': serializer.toJson<String>(handle),
      'displayName': serializer.toJson<String>(displayName),
      'email': serializer.toJson<String?>(email),
      'emailVerified': serializer.toJson<bool>(emailVerified),
      'avatarRef': serializer.toJson<String?>(avatarRef),
      'gitAuthorName': serializer.toJson<String?>(gitAuthorName),
      'gitAuthorEmail': serializer.toJson<String?>(gitAuthorEmail),
      'ssoSubject': serializer.toJson<String?>(ssoSubject),
      'ssoIssuer': serializer.toJson<String?>(ssoIssuer),
      'deactivatedAt': serializer.toJson<DateTime?>(deactivatedAt),
      'onboardingFinishedAt': serializer.toJson<DateTime?>(
        onboardingFinishedAt,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UsersTableData copyWith({
    String? id,
    String? handle,
    String? displayName,
    Value<String?> email = const Value.absent(),
    bool? emailVerified,
    Value<String?> avatarRef = const Value.absent(),
    Value<String?> gitAuthorName = const Value.absent(),
    Value<String?> gitAuthorEmail = const Value.absent(),
    Value<String?> ssoSubject = const Value.absent(),
    Value<String?> ssoIssuer = const Value.absent(),
    Value<DateTime?> deactivatedAt = const Value.absent(),
    Value<DateTime?> onboardingFinishedAt = const Value.absent(),
    DateTime? createdAt,
  }) => UsersTableData(
    id: id ?? this.id,
    handle: handle ?? this.handle,
    displayName: displayName ?? this.displayName,
    email: email.present ? email.value : this.email,
    emailVerified: emailVerified ?? this.emailVerified,
    avatarRef: avatarRef.present ? avatarRef.value : this.avatarRef,
    gitAuthorName: gitAuthorName.present
        ? gitAuthorName.value
        : this.gitAuthorName,
    gitAuthorEmail: gitAuthorEmail.present
        ? gitAuthorEmail.value
        : this.gitAuthorEmail,
    ssoSubject: ssoSubject.present ? ssoSubject.value : this.ssoSubject,
    ssoIssuer: ssoIssuer.present ? ssoIssuer.value : this.ssoIssuer,
    deactivatedAt: deactivatedAt.present
        ? deactivatedAt.value
        : this.deactivatedAt,
    onboardingFinishedAt: onboardingFinishedAt.present
        ? onboardingFinishedAt.value
        : this.onboardingFinishedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  UsersTableData copyWithCompanion(UsersTableCompanion data) {
    return UsersTableData(
      id: data.id.present ? data.id.value : this.id,
      handle: data.handle.present ? data.handle.value : this.handle,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      email: data.email.present ? data.email.value : this.email,
      emailVerified: data.emailVerified.present
          ? data.emailVerified.value
          : this.emailVerified,
      avatarRef: data.avatarRef.present ? data.avatarRef.value : this.avatarRef,
      gitAuthorName: data.gitAuthorName.present
          ? data.gitAuthorName.value
          : this.gitAuthorName,
      gitAuthorEmail: data.gitAuthorEmail.present
          ? data.gitAuthorEmail.value
          : this.gitAuthorEmail,
      ssoSubject: data.ssoSubject.present
          ? data.ssoSubject.value
          : this.ssoSubject,
      ssoIssuer: data.ssoIssuer.present ? data.ssoIssuer.value : this.ssoIssuer,
      deactivatedAt: data.deactivatedAt.present
          ? data.deactivatedAt.value
          : this.deactivatedAt,
      onboardingFinishedAt: data.onboardingFinishedAt.present
          ? data.onboardingFinishedAt.value
          : this.onboardingFinishedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableData(')
          ..write('id: $id, ')
          ..write('handle: $handle, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('emailVerified: $emailVerified, ')
          ..write('avatarRef: $avatarRef, ')
          ..write('gitAuthorName: $gitAuthorName, ')
          ..write('gitAuthorEmail: $gitAuthorEmail, ')
          ..write('ssoSubject: $ssoSubject, ')
          ..write('ssoIssuer: $ssoIssuer, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('onboardingFinishedAt: $onboardingFinishedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    handle,
    displayName,
    email,
    emailVerified,
    avatarRef,
    gitAuthorName,
    gitAuthorEmail,
    ssoSubject,
    ssoIssuer,
    deactivatedAt,
    onboardingFinishedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersTableData &&
          other.id == this.id &&
          other.handle == this.handle &&
          other.displayName == this.displayName &&
          other.email == this.email &&
          other.emailVerified == this.emailVerified &&
          other.avatarRef == this.avatarRef &&
          other.gitAuthorName == this.gitAuthorName &&
          other.gitAuthorEmail == this.gitAuthorEmail &&
          other.ssoSubject == this.ssoSubject &&
          other.ssoIssuer == this.ssoIssuer &&
          other.deactivatedAt == this.deactivatedAt &&
          other.onboardingFinishedAt == this.onboardingFinishedAt &&
          other.createdAt == this.createdAt);
}

class UsersTableCompanion extends UpdateCompanion<UsersTableData> {
  final Value<String> id;
  final Value<String> handle;
  final Value<String> displayName;
  final Value<String?> email;
  final Value<bool> emailVerified;
  final Value<String?> avatarRef;
  final Value<String?> gitAuthorName;
  final Value<String?> gitAuthorEmail;
  final Value<String?> ssoSubject;
  final Value<String?> ssoIssuer;
  final Value<DateTime?> deactivatedAt;
  final Value<DateTime?> onboardingFinishedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UsersTableCompanion({
    this.id = const Value.absent(),
    this.handle = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.emailVerified = const Value.absent(),
    this.avatarRef = const Value.absent(),
    this.gitAuthorName = const Value.absent(),
    this.gitAuthorEmail = const Value.absent(),
    this.ssoSubject = const Value.absent(),
    this.ssoIssuer = const Value.absent(),
    this.deactivatedAt = const Value.absent(),
    this.onboardingFinishedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersTableCompanion.insert({
    required String id,
    required String handle,
    required String displayName,
    this.email = const Value.absent(),
    this.emailVerified = const Value.absent(),
    this.avatarRef = const Value.absent(),
    this.gitAuthorName = const Value.absent(),
    this.gitAuthorEmail = const Value.absent(),
    this.ssoSubject = const Value.absent(),
    this.ssoIssuer = const Value.absent(),
    this.deactivatedAt = const Value.absent(),
    this.onboardingFinishedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       handle = Value(handle),
       displayName = Value(displayName);
  static Insertable<UsersTableData> custom({
    Expression<String>? id,
    Expression<String>? handle,
    Expression<String>? displayName,
    Expression<String>? email,
    Expression<bool>? emailVerified,
    Expression<String>? avatarRef,
    Expression<String>? gitAuthorName,
    Expression<String>? gitAuthorEmail,
    Expression<String>? ssoSubject,
    Expression<String>? ssoIssuer,
    Expression<DateTime>? deactivatedAt,
    Expression<DateTime>? onboardingFinishedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (handle != null) 'handle': handle,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
      if (emailVerified != null) 'email_verified': emailVerified,
      if (avatarRef != null) 'avatar_ref': avatarRef,
      if (gitAuthorName != null) 'git_author_name': gitAuthorName,
      if (gitAuthorEmail != null) 'git_author_email': gitAuthorEmail,
      if (ssoSubject != null) 'sso_subject': ssoSubject,
      if (ssoIssuer != null) 'sso_issuer': ssoIssuer,
      if (deactivatedAt != null) 'deactivated_at': deactivatedAt,
      if (onboardingFinishedAt != null)
        'onboarding_finished_at': onboardingFinishedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? handle,
    Value<String>? displayName,
    Value<String?>? email,
    Value<bool>? emailVerified,
    Value<String?>? avatarRef,
    Value<String?>? gitAuthorName,
    Value<String?>? gitAuthorEmail,
    Value<String?>? ssoSubject,
    Value<String?>? ssoIssuer,
    Value<DateTime?>? deactivatedAt,
    Value<DateTime?>? onboardingFinishedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UsersTableCompanion(
      id: id ?? this.id,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      avatarRef: avatarRef ?? this.avatarRef,
      gitAuthorName: gitAuthorName ?? this.gitAuthorName,
      gitAuthorEmail: gitAuthorEmail ?? this.gitAuthorEmail,
      ssoSubject: ssoSubject ?? this.ssoSubject,
      ssoIssuer: ssoIssuer ?? this.ssoIssuer,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      onboardingFinishedAt: onboardingFinishedAt ?? this.onboardingFinishedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (handle.present) {
      map['handle'] = Variable<String>(handle.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (emailVerified.present) {
      map['email_verified'] = Variable<bool>(emailVerified.value);
    }
    if (avatarRef.present) {
      map['avatar_ref'] = Variable<String>(avatarRef.value);
    }
    if (gitAuthorName.present) {
      map['git_author_name'] = Variable<String>(gitAuthorName.value);
    }
    if (gitAuthorEmail.present) {
      map['git_author_email'] = Variable<String>(gitAuthorEmail.value);
    }
    if (ssoSubject.present) {
      map['sso_subject'] = Variable<String>(ssoSubject.value);
    }
    if (ssoIssuer.present) {
      map['sso_issuer'] = Variable<String>(ssoIssuer.value);
    }
    if (deactivatedAt.present) {
      map['deactivated_at'] = Variable<DateTime>(deactivatedAt.value);
    }
    if (onboardingFinishedAt.present) {
      map['onboarding_finished_at'] = Variable<DateTime>(
        onboardingFinishedAt.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableCompanion(')
          ..write('id: $id, ')
          ..write('handle: $handle, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('emailVerified: $emailVerified, ')
          ..write('avatarRef: $avatarRef, ')
          ..write('gitAuthorName: $gitAuthorName, ')
          ..write('gitAuthorEmail: $gitAuthorEmail, ')
          ..write('ssoSubject: $ssoSubject, ')
          ..write('ssoIssuer: $ssoIssuer, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('onboardingFinishedAt: $onboardingFinishedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkspacesTableTable extends WorkspacesTable
    with TableInfo<$WorkspacesTableTable, WorkspacesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _secretExcludeGlobsMeta =
      const VerificationMeta('secretExcludeGlobs');
  @override
  late final GeneratedColumn<String> secretExcludeGlobs =
      GeneratedColumn<String>(
        'secret_exclude_globs',
        aliasedName,
        false,
        check: () => isJsonArray(secretExcludeGlobs),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _reviewConcurrencyMeta = const VerificationMeta(
    'reviewConcurrency',
  );
  @override
  late final GeneratedColumn<int> reviewConcurrency = GeneratedColumn<int>(
    'review_concurrency',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _autoPublishReviewMeta = const VerificationMeta(
    'autoPublishReview',
  );
  @override
  late final GeneratedColumn<bool> autoPublishReview = GeneratedColumn<bool>(
    'auto_publish_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_publish_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _connectModeMeta = const VerificationMeta(
    'connectMode',
  );
  @override
  late final GeneratedColumn<String> connectMode = GeneratedColumn<String>(
    'connect_mode',
    aliasedName,
    false,
    check: () => connectMode.isIn(PlatformStoredValues.workspaceConnectMode),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('inherit'),
  );
  static const VerificationMeta _connectUrlMeta = const VerificationMeta(
    'connectUrl',
  );
  @override
  late final GeneratedColumn<String> connectUrl = GeneratedColumn<String>(
    'connect_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _githubAppIdMeta = const VerificationMeta(
    'githubAppId',
  );
  @override
  late final GeneratedColumn<String> githubAppId = GeneratedColumn<String>(
    'github_app_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    logoPath,
    ownerUserId,
    secretExcludeGlobs,
    reviewConcurrency,
    autoPublishReview,
    connectMode,
    connectUrl,
    githubAppId,
    position,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspacesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('secret_exclude_globs')) {
      context.handle(
        _secretExcludeGlobsMeta,
        secretExcludeGlobs.isAcceptableOrUnknown(
          data['secret_exclude_globs']!,
          _secretExcludeGlobsMeta,
        ),
      );
    }
    if (data.containsKey('review_concurrency')) {
      context.handle(
        _reviewConcurrencyMeta,
        reviewConcurrency.isAcceptableOrUnknown(
          data['review_concurrency']!,
          _reviewConcurrencyMeta,
        ),
      );
    }
    if (data.containsKey('auto_publish_review')) {
      context.handle(
        _autoPublishReviewMeta,
        autoPublishReview.isAcceptableOrUnknown(
          data['auto_publish_review']!,
          _autoPublishReviewMeta,
        ),
      );
    }
    if (data.containsKey('connect_mode')) {
      context.handle(
        _connectModeMeta,
        connectMode.isAcceptableOrUnknown(
          data['connect_mode']!,
          _connectModeMeta,
        ),
      );
    }
    if (data.containsKey('connect_url')) {
      context.handle(
        _connectUrlMeta,
        connectUrl.isAcceptableOrUnknown(data['connect_url']!, _connectUrlMeta),
      );
    }
    if (data.containsKey('github_app_id')) {
      context.handle(
        _githubAppIdMeta,
        githubAppId.isAcceptableOrUnknown(
          data['github_app_id']!,
          _githubAppIdMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspacesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspacesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      ),
      secretExcludeGlobs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_exclude_globs'],
      )!,
      reviewConcurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_concurrency'],
      )!,
      autoPublishReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_publish_review'],
      )!,
      connectMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connect_mode'],
      )!,
      connectUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connect_url'],
      )!,
      githubAppId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}github_app_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WorkspacesTableTable createAlias(String alias) {
    return $WorkspacesTableTable(attachedDatabase, alias);
  }
}

class WorkspacesTableData extends DataClass
    implements Insertable<WorkspacesTableData> {
  /// Unique workspace identifier.
  final String id;

  /// Workspace display name (user-supplied at creation).
  final String name;

  /// Optional path to a local image file used as the workspace logo.
  final String? logoPath;

  /// The user who owns this workspace (holds the `owner` membership role).
  /// Nullable in SQL only until the identity bootstrap backfills it on first
  /// boot; treated as required everywhere else. A user is never deleted
  /// (attribution is permanent), and must not be while they own a workspace.
  final String? ownerUserId;

  /// JSON array of glob patterns whose matching paths are hard-blocked from
  /// guest/viewer visibility on code-bearing surfaces (secret exclusion).
  final String secretExcludeGlobs;

  /// Default fan-out for parallel reviewer dispatch on this workspace.
  /// `dispatch_reviewers` MCP tool uses this when no explicit `concurrency`
  /// argument is provided.
  final int reviewConcurrency;

  /// Whether a completed review publishes to GitHub automatically (opt-in;
  /// off by default — publishing is otherwise user-gated behind the
  /// "Publish to GitHub" action, which itself stays ActionClass-guarded).
  final bool autoPublishReview;

  /// Whose provider apps this workspace uses (`inherit` / `hosted` /
  /// `custom` / `own`): the server's choice, a Connect of its own, or its own
  /// apps. Typed because the server reads it on every credential path — not
  /// an opaque `workspace_settings` string. A `WorkspaceConnectMode` wire
  /// name.
  final String connectMode;

  /// The canonical Connect base URL when [connectMode] is `custom`. Empty
  /// otherwise.
  final String connectUrl;

  /// Numeric id of this workspace's own GitHub App, used while [connectMode]
  /// is `own`. Empty when none is saved. The private key is never a column;
  /// it lives in `secrets.json`.
  final String githubAppId;

  /// The operator's manual order for the workspace switcher / manager
  /// (drag-to-reorder in "manage workspaces"). Lower sorts first;
  /// [createdAt] is the stable tiebreak. Mirrors `repos.position` — one manual
  /// order per list, server-owned, so every client (desktop/web/phone) renders
  /// workspaces in the same sequence.
  final int position;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Soft-delete timestamp. When non-null, the workspace is considered deleted.
  final DateTime? deletedAt;
  const WorkspacesTableData({
    required this.id,
    required this.name,
    this.logoPath,
    this.ownerUserId,
    required this.secretExcludeGlobs,
    required this.reviewConcurrency,
    required this.autoPublishReview,
    required this.connectMode,
    required this.connectUrl,
    required this.githubAppId,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    map['secret_exclude_globs'] = Variable<String>(secretExcludeGlobs);
    map['review_concurrency'] = Variable<int>(reviewConcurrency);
    map['auto_publish_review'] = Variable<bool>(autoPublishReview);
    map['connect_mode'] = Variable<String>(connectMode);
    map['connect_url'] = Variable<String>(connectUrl);
    map['github_app_id'] = Variable<String>(githubAppId);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  WorkspacesTableCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesTableCompanion(
      id: Value(id),
      name: Value(name),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
      secretExcludeGlobs: Value(secretExcludeGlobs),
      reviewConcurrency: Value(reviewConcurrency),
      autoPublishReview: Value(autoPublishReview),
      connectMode: Value(connectMode),
      connectUrl: Value(connectUrl),
      githubAppId: Value(githubAppId),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkspacesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspacesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
      secretExcludeGlobs: serializer.fromJson<String>(
        json['secretExcludeGlobs'],
      ),
      reviewConcurrency: serializer.fromJson<int>(json['reviewConcurrency']),
      autoPublishReview: serializer.fromJson<bool>(json['autoPublishReview']),
      connectMode: serializer.fromJson<String>(json['connectMode']),
      connectUrl: serializer.fromJson<String>(json['connectUrl']),
      githubAppId: serializer.fromJson<String>(json['githubAppId']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'logoPath': serializer.toJson<String?>(logoPath),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
      'secretExcludeGlobs': serializer.toJson<String>(secretExcludeGlobs),
      'reviewConcurrency': serializer.toJson<int>(reviewConcurrency),
      'autoPublishReview': serializer.toJson<bool>(autoPublishReview),
      'connectMode': serializer.toJson<String>(connectMode),
      'connectUrl': serializer.toJson<String>(connectUrl),
      'githubAppId': serializer.toJson<String>(githubAppId),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  WorkspacesTableData copyWith({
    String? id,
    String? name,
    Value<String?> logoPath = const Value.absent(),
    Value<String?> ownerUserId = const Value.absent(),
    String? secretExcludeGlobs,
    int? reviewConcurrency,
    bool? autoPublishReview,
    String? connectMode,
    String? connectUrl,
    String? githubAppId,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => WorkspacesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
    secretExcludeGlobs: secretExcludeGlobs ?? this.secretExcludeGlobs,
    reviewConcurrency: reviewConcurrency ?? this.reviewConcurrency,
    autoPublishReview: autoPublishReview ?? this.autoPublishReview,
    connectMode: connectMode ?? this.connectMode,
    connectUrl: connectUrl ?? this.connectUrl,
    githubAppId: githubAppId ?? this.githubAppId,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkspacesTableData copyWithCompanion(WorkspacesTableCompanion data) {
    return WorkspacesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      secretExcludeGlobs: data.secretExcludeGlobs.present
          ? data.secretExcludeGlobs.value
          : this.secretExcludeGlobs,
      reviewConcurrency: data.reviewConcurrency.present
          ? data.reviewConcurrency.value
          : this.reviewConcurrency,
      autoPublishReview: data.autoPublishReview.present
          ? data.autoPublishReview.value
          : this.autoPublishReview,
      connectMode: data.connectMode.present
          ? data.connectMode.value
          : this.connectMode,
      connectUrl: data.connectUrl.present
          ? data.connectUrl.value
          : this.connectUrl,
      githubAppId: data.githubAppId.present
          ? data.githubAppId.value
          : this.githubAppId,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('logoPath: $logoPath, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('secretExcludeGlobs: $secretExcludeGlobs, ')
          ..write('reviewConcurrency: $reviewConcurrency, ')
          ..write('autoPublishReview: $autoPublishReview, ')
          ..write('connectMode: $connectMode, ')
          ..write('connectUrl: $connectUrl, ')
          ..write('githubAppId: $githubAppId, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    logoPath,
    ownerUserId,
    secretExcludeGlobs,
    reviewConcurrency,
    autoPublishReview,
    connectMode,
    connectUrl,
    githubAppId,
    position,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspacesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.logoPath == this.logoPath &&
          other.ownerUserId == this.ownerUserId &&
          other.secretExcludeGlobs == this.secretExcludeGlobs &&
          other.reviewConcurrency == this.reviewConcurrency &&
          other.autoPublishReview == this.autoPublishReview &&
          other.connectMode == this.connectMode &&
          other.connectUrl == this.connectUrl &&
          other.githubAppId == this.githubAppId &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WorkspacesTableCompanion extends UpdateCompanion<WorkspacesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> logoPath;
  final Value<String?> ownerUserId;
  final Value<String> secretExcludeGlobs;
  final Value<int> reviewConcurrency;
  final Value<bool> autoPublishReview;
  final Value<String> connectMode;
  final Value<String> connectUrl;
  final Value<String> githubAppId;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const WorkspacesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.secretExcludeGlobs = const Value.absent(),
    this.reviewConcurrency = const Value.absent(),
    this.autoPublishReview = const Value.absent(),
    this.connectMode = const Value.absent(),
    this.connectUrl = const Value.absent(),
    this.githubAppId = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesTableCompanion.insert({
    required String id,
    required String name,
    this.logoPath = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.secretExcludeGlobs = const Value.absent(),
    this.reviewConcurrency = const Value.absent(),
    this.autoPublishReview = const Value.absent(),
    this.connectMode = const Value.absent(),
    this.connectUrl = const Value.absent(),
    this.githubAppId = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<WorkspacesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? logoPath,
    Expression<String>? ownerUserId,
    Expression<String>? secretExcludeGlobs,
    Expression<int>? reviewConcurrency,
    Expression<bool>? autoPublishReview,
    Expression<String>? connectMode,
    Expression<String>? connectUrl,
    Expression<String>? githubAppId,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (logoPath != null) 'logo_path': logoPath,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (secretExcludeGlobs != null)
        'secret_exclude_globs': secretExcludeGlobs,
      if (reviewConcurrency != null) 'review_concurrency': reviewConcurrency,
      if (autoPublishReview != null) 'auto_publish_review': autoPublishReview,
      if (connectMode != null) 'connect_mode': connectMode,
      if (connectUrl != null) 'connect_url': connectUrl,
      if (githubAppId != null) 'github_app_id': githubAppId,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? logoPath,
    Value<String?>? ownerUserId,
    Value<String>? secretExcludeGlobs,
    Value<int>? reviewConcurrency,
    Value<bool>? autoPublishReview,
    Value<String>? connectMode,
    Value<String>? connectUrl,
    Value<String>? githubAppId,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WorkspacesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      logoPath: logoPath ?? this.logoPath,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      secretExcludeGlobs: secretExcludeGlobs ?? this.secretExcludeGlobs,
      reviewConcurrency: reviewConcurrency ?? this.reviewConcurrency,
      autoPublishReview: autoPublishReview ?? this.autoPublishReview,
      connectMode: connectMode ?? this.connectMode,
      connectUrl: connectUrl ?? this.connectUrl,
      githubAppId: githubAppId ?? this.githubAppId,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (secretExcludeGlobs.present) {
      map['secret_exclude_globs'] = Variable<String>(secretExcludeGlobs.value);
    }
    if (reviewConcurrency.present) {
      map['review_concurrency'] = Variable<int>(reviewConcurrency.value);
    }
    if (autoPublishReview.present) {
      map['auto_publish_review'] = Variable<bool>(autoPublishReview.value);
    }
    if (connectMode.present) {
      map['connect_mode'] = Variable<String>(connectMode.value);
    }
    if (connectUrl.present) {
      map['connect_url'] = Variable<String>(connectUrl.value);
    }
    if (githubAppId.present) {
      map['github_app_id'] = Variable<String>(githubAppId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('logoPath: $logoPath, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('secretExcludeGlobs: $secretExcludeGlobs, ')
          ..write('reviewConcurrency: $reviewConcurrency, ')
          ..write('autoPublishReview: $autoPublishReview, ')
          ..write('connectMode: $connectMode, ')
          ..write('connectUrl: $connectUrl, ')
          ..write('githubAppId: $githubAppId, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTableTable extends UserPreferencesTable
    with TableInfo<$UserPreferencesTableTable, UserPreferencesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreferencesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, key};
  @override
  UserPreferencesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferencesTableData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserPreferencesTableTable createAlias(String alias) {
    return $UserPreferencesTableTable(attachedDatabase, alias);
  }
}

class UserPreferencesTableData extends DataClass
    implements Insertable<UserPreferencesTableData> {
  /// The owning user.
  final String userId;

  /// Preference key (client-defined namespace, e.g. `theme_mode`).
  final String key;

  /// Opaque preference value.
  final String value;

  /// When the value was last written.
  final DateTime updatedAt;
  const UserPreferencesTableData({
    required this.userId,
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesTableCompanion(
      userId: Value(userId),
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserPreferencesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferencesTableData(
      userId: serializer.fromJson<String>(json['userId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserPreferencesTableData copyWith({
    String? userId,
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => UserPreferencesTableData(
    userId: userId ?? this.userId,
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserPreferencesTableData copyWithCompanion(
    UserPreferencesTableCompanion data,
  ) {
    return UserPreferencesTableData(
      userId: data.userId.present ? data.userId.value : this.userId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableData(')
          ..write('userId: $userId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferencesTableData &&
          other.userId == this.userId &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class UserPreferencesTableCompanion
    extends UpdateCompanion<UserPreferencesTableData> {
  final Value<String> userId;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserPreferencesTableCompanion({
    this.userId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferencesTableCompanion.insert({
    required String userId,
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       key = Value(key),
       value = Value(value);
  static Insertable<UserPreferencesTableData> custom({
    Expression<String>? userId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferencesTableCompanion copyWith({
    Value<String>? userId,
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserPreferencesTableCompanion(
      userId: userId ?? this.userId,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableCompanion(')
          ..write('userId: $userId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PairedDevicesTableTable extends PairedDevicesTable
    with TableInfo<$PairedDevicesTableTable, PairedDevicesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PairedDevicesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _landingWorkspaceIdMeta =
      const VerificationMeta('landingWorkspaceId');
  @override
  late final GeneratedColumn<String> landingWorkspaceId =
      GeneratedColumn<String>(
        'landing_workspace_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workspaces (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('web'),
  );
  static const VerificationMeta _pskRefMeta = const VerificationMeta('pskRef');
  @override
  late final GeneratedColumn<String> pskRef = GeneratedColumn<String>(
    'psk_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteFingerprintMeta = const VerificationMeta(
    'remoteFingerprint',
  );
  @override
  late final GeneratedColumn<String> remoteFingerprint =
      GeneratedColumn<String>(
        'remote_fingerprint',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(PlatformStoredValues.pairedDeviceStatus),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pendingConfirm'),
  );
  static const VerificationMeta _pairedAtMeta = const VerificationMeta(
    'pairedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pairedAt = GeneratedColumn<DateTime>(
    'paired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    landingWorkspaceId,
    label,
    platform,
    pskRef,
    remoteFingerprint,
    status,
    pairedAt,
    lastSeenAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paired_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<PairedDevicesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('landing_workspace_id')) {
      context.handle(
        _landingWorkspaceIdMeta,
        landingWorkspaceId.isAcceptableOrUnknown(
          data['landing_workspace_id']!,
          _landingWorkspaceIdMeta,
        ),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    }
    if (data.containsKey('psk_ref')) {
      context.handle(
        _pskRefMeta,
        pskRef.isAcceptableOrUnknown(data['psk_ref']!, _pskRefMeta),
      );
    } else if (isInserting) {
      context.missing(_pskRefMeta);
    }
    if (data.containsKey('remote_fingerprint')) {
      context.handle(
        _remoteFingerprintMeta,
        remoteFingerprint.isAcceptableOrUnknown(
          data['remote_fingerprint']!,
          _remoteFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('paired_at')) {
      context.handle(
        _pairedAtMeta,
        pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PairedDevicesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PairedDevicesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      landingWorkspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}landing_workspace_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      pskRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}psk_ref'],
      )!,
      remoteFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_fingerprint'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      pairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paired_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
    );
  }

  @override
  $PairedDevicesTableTable createAlias(String alias) {
    return $PairedDevicesTableTable(attachedDatabase, alias);
  }
}

class PairedDevicesTableData extends DataClass
    implements Insertable<PairedDevicesTableData> {
  /// Unique device id (generated at pairing).
  final String id;

  /// The user this device authenticates as; the device goes with them.
  final String userId;

  /// The workspace active at pairing time (seed for the session binding), or
  /// null when it was paired outside one (the local desktop, a web sign-in).
  /// History, not ownership: cleared if the workspace row ever goes.
  final String? landingWorkspaceId;

  /// User-editable label (e.g. "iPhone").
  final String label;

  /// Platform string reported by the phone ("ios", "android", "web").
  final String platform;

  /// Secure-store key referencing this device's PSK
  /// (`paired_device_psk_<id>`).
  final String pskRef;

  /// Pinned remote DTLS fingerprint (TOFU on first connect).
  final String? remoteFingerprint;

  /// Pairing status: a [PlatformStoredValues.pairedDeviceStatus] value.
  final String status;

  /// When the device was paired.
  final DateTime pairedAt;

  /// When the device last connected.
  final DateTime? lastSeenAt;

  /// When this credential becomes invalid and the desktop must fail it closed.
  ///
  /// Two-phase: for a `pendingConfirm` device it is the short pairing-offer
  /// window (the QR's ~5 min) — if the user never confirms in time, the offer is
  /// purged. Once confirmed (`active`) it is reset to an absolute credential
  /// lifetime, after which the phone must re-pair. The desktop checks this in
  /// both connect gates so a leaked link is time-boxed rather than a permanent
  /// backdoor. Null means "no expiry" (legacy rows upgraded before this column).
  final DateTime? expiresAt;
  const PairedDevicesTableData({
    required this.id,
    required this.userId,
    this.landingWorkspaceId,
    required this.label,
    required this.platform,
    required this.pskRef,
    this.remoteFingerprint,
    required this.status,
    required this.pairedAt,
    this.lastSeenAt,
    this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || landingWorkspaceId != null) {
      map['landing_workspace_id'] = Variable<String>(landingWorkspaceId);
    }
    map['label'] = Variable<String>(label);
    map['platform'] = Variable<String>(platform);
    map['psk_ref'] = Variable<String>(pskRef);
    if (!nullToAbsent || remoteFingerprint != null) {
      map['remote_fingerprint'] = Variable<String>(remoteFingerprint);
    }
    map['status'] = Variable<String>(status);
    map['paired_at'] = Variable<DateTime>(pairedAt);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    return map;
  }

  PairedDevicesTableCompanion toCompanion(bool nullToAbsent) {
    return PairedDevicesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      landingWorkspaceId: landingWorkspaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(landingWorkspaceId),
      label: Value(label),
      platform: Value(platform),
      pskRef: Value(pskRef),
      remoteFingerprint: remoteFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteFingerprint),
      status: Value(status),
      pairedAt: Value(pairedAt),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory PairedDevicesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PairedDevicesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      landingWorkspaceId: serializer.fromJson<String?>(
        json['landingWorkspaceId'],
      ),
      label: serializer.fromJson<String>(json['label']),
      platform: serializer.fromJson<String>(json['platform']),
      pskRef: serializer.fromJson<String>(json['pskRef']),
      remoteFingerprint: serializer.fromJson<String?>(
        json['remoteFingerprint'],
      ),
      status: serializer.fromJson<String>(json['status']),
      pairedAt: serializer.fromJson<DateTime>(json['pairedAt']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'landingWorkspaceId': serializer.toJson<String?>(landingWorkspaceId),
      'label': serializer.toJson<String>(label),
      'platform': serializer.toJson<String>(platform),
      'pskRef': serializer.toJson<String>(pskRef),
      'remoteFingerprint': serializer.toJson<String?>(remoteFingerprint),
      'status': serializer.toJson<String>(status),
      'pairedAt': serializer.toJson<DateTime>(pairedAt),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
    };
  }

  PairedDevicesTableData copyWith({
    String? id,
    String? userId,
    Value<String?> landingWorkspaceId = const Value.absent(),
    String? label,
    String? platform,
    String? pskRef,
    Value<String?> remoteFingerprint = const Value.absent(),
    String? status,
    DateTime? pairedAt,
    Value<DateTime?> lastSeenAt = const Value.absent(),
    Value<DateTime?> expiresAt = const Value.absent(),
  }) => PairedDevicesTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    landingWorkspaceId: landingWorkspaceId.present
        ? landingWorkspaceId.value
        : this.landingWorkspaceId,
    label: label ?? this.label,
    platform: platform ?? this.platform,
    pskRef: pskRef ?? this.pskRef,
    remoteFingerprint: remoteFingerprint.present
        ? remoteFingerprint.value
        : this.remoteFingerprint,
    status: status ?? this.status,
    pairedAt: pairedAt ?? this.pairedAt,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
  );
  PairedDevicesTableData copyWithCompanion(PairedDevicesTableCompanion data) {
    return PairedDevicesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      landingWorkspaceId: data.landingWorkspaceId.present
          ? data.landingWorkspaceId.value
          : this.landingWorkspaceId,
      label: data.label.present ? data.label.value : this.label,
      platform: data.platform.present ? data.platform.value : this.platform,
      pskRef: data.pskRef.present ? data.pskRef.value : this.pskRef,
      remoteFingerprint: data.remoteFingerprint.present
          ? data.remoteFingerprint.value
          : this.remoteFingerprint,
      status: data.status.present ? data.status.value : this.status,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevicesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('landingWorkspaceId: $landingWorkspaceId, ')
          ..write('label: $label, ')
          ..write('platform: $platform, ')
          ..write('pskRef: $pskRef, ')
          ..write('remoteFingerprint: $remoteFingerprint, ')
          ..write('status: $status, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    landingWorkspaceId,
    label,
    platform,
    pskRef,
    remoteFingerprint,
    status,
    pairedAt,
    lastSeenAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PairedDevicesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.landingWorkspaceId == this.landingWorkspaceId &&
          other.label == this.label &&
          other.platform == this.platform &&
          other.pskRef == this.pskRef &&
          other.remoteFingerprint == this.remoteFingerprint &&
          other.status == this.status &&
          other.pairedAt == this.pairedAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.expiresAt == this.expiresAt);
}

class PairedDevicesTableCompanion
    extends UpdateCompanion<PairedDevicesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> landingWorkspaceId;
  final Value<String> label;
  final Value<String> platform;
  final Value<String> pskRef;
  final Value<String?> remoteFingerprint;
  final Value<String> status;
  final Value<DateTime> pairedAt;
  final Value<DateTime?> lastSeenAt;
  final Value<DateTime?> expiresAt;
  final Value<int> rowid;
  const PairedDevicesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.landingWorkspaceId = const Value.absent(),
    this.label = const Value.absent(),
    this.platform = const Value.absent(),
    this.pskRef = const Value.absent(),
    this.remoteFingerprint = const Value.absent(),
    this.status = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PairedDevicesTableCompanion.insert({
    required String id,
    required String userId,
    this.landingWorkspaceId = const Value.absent(),
    required String label,
    this.platform = const Value.absent(),
    required String pskRef,
    this.remoteFingerprint = const Value.absent(),
    this.status = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       label = Value(label),
       pskRef = Value(pskRef);
  static Insertable<PairedDevicesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? landingWorkspaceId,
    Expression<String>? label,
    Expression<String>? platform,
    Expression<String>? pskRef,
    Expression<String>? remoteFingerprint,
    Expression<String>? status,
    Expression<DateTime>? pairedAt,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (landingWorkspaceId != null)
        'landing_workspace_id': landingWorkspaceId,
      if (label != null) 'label': label,
      if (platform != null) 'platform': platform,
      if (pskRef != null) 'psk_ref': pskRef,
      if (remoteFingerprint != null) 'remote_fingerprint': remoteFingerprint,
      if (status != null) 'status': status,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PairedDevicesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? landingWorkspaceId,
    Value<String>? label,
    Value<String>? platform,
    Value<String>? pskRef,
    Value<String?>? remoteFingerprint,
    Value<String>? status,
    Value<DateTime>? pairedAt,
    Value<DateTime?>? lastSeenAt,
    Value<DateTime?>? expiresAt,
    Value<int>? rowid,
  }) {
    return PairedDevicesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      landingWorkspaceId: landingWorkspaceId ?? this.landingWorkspaceId,
      label: label ?? this.label,
      platform: platform ?? this.platform,
      pskRef: pskRef ?? this.pskRef,
      remoteFingerprint: remoteFingerprint ?? this.remoteFingerprint,
      status: status ?? this.status,
      pairedAt: pairedAt ?? this.pairedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (landingWorkspaceId.present) {
      map['landing_workspace_id'] = Variable<String>(landingWorkspaceId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (pskRef.present) {
      map['psk_ref'] = Variable<String>(pskRef.value);
    }
    if (remoteFingerprint.present) {
      map['remote_fingerprint'] = Variable<String>(remoteFingerprint.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<DateTime>(pairedAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevicesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('landingWorkspaceId: $landingWorkspaceId, ')
          ..write('label: $label, ')
          ..write('platform: $platform, ')
          ..write('pskRef: $pskRef, ')
          ..write('remoteFingerprint: $remoteFingerprint, ')
          ..write('status: $status, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RssFeedsTableTable extends RssFeedsTable
    with TableInfo<$RssFeedsTableTable, RssFeedsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssFeedsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _userAgentMeta = const VerificationMeta(
    'userAgent',
  );
  @override
  late final GeneratedColumn<String> userAgent = GeneratedColumn<String>(
    'user_agent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchedAt =
      GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    url,
    description,
    iconUrl,
    userAgent,
    enabled,
    lastFetchedAt,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_feeds';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssFeedsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    if (data.containsKey('user_agent')) {
      context.handle(
        _userAgentMeta,
        userAgent.isAcceptableOrUnknown(data['user_agent']!, _userAgentMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RssFeedsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssFeedsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      )!,
      userAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_agent'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RssFeedsTableTable createAlias(String alias) {
    return $RssFeedsTableTable(attachedDatabase, alias);
  }
}

class RssFeedsTableData extends DataClass
    implements Insertable<RssFeedsTableData> {
  /// Unique feed identifier (uuid v4).
  final String id;

  /// Owning user — the feed list is per-user, never shared.
  final String userId;

  /// Display name (e.g. "The Verge").
  final String name;

  /// Feed URL.
  final String url;

  /// Optional description shown in feed-management UI.
  final String description;

  /// Optional icon URL parsed from the feed (or favicon fallback).
  final String iconUrl;

  /// Optional custom User-Agent for this feed (empty = use default).
  final String userAgent;

  /// Whether this feed is active (off = not fetched, not shown).
  final bool enabled;

  /// Last successful fetch timestamp. Null if never fetched.
  final DateTime? lastFetchedAt;

  /// Last error message if the last fetch failed.
  final String? lastError;

  /// Created at.
  final DateTime createdAt;

  /// Updated at.
  final DateTime updatedAt;
  const RssFeedsTableData({
    required this.id,
    required this.userId,
    required this.name,
    required this.url,
    required this.description,
    required this.iconUrl,
    required this.userAgent,
    required this.enabled,
    this.lastFetchedAt,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    map['description'] = Variable<String>(description);
    map['icon_url'] = Variable<String>(iconUrl);
    map['user_agent'] = Variable<String>(userAgent);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || lastFetchedAt != null) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RssFeedsTableCompanion toCompanion(bool nullToAbsent) {
    return RssFeedsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      url: Value(url),
      description: Value(description),
      iconUrl: Value(iconUrl),
      userAgent: Value(userAgent),
      enabled: Value(enabled),
      lastFetchedAt: lastFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RssFeedsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssFeedsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      description: serializer.fromJson<String>(json['description']),
      iconUrl: serializer.fromJson<String>(json['iconUrl']),
      userAgent: serializer.fromJson<String>(json['userAgent']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      lastFetchedAt: serializer.fromJson<DateTime?>(json['lastFetchedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'description': serializer.toJson<String>(description),
      'iconUrl': serializer.toJson<String>(iconUrl),
      'userAgent': serializer.toJson<String>(userAgent),
      'enabled': serializer.toJson<bool>(enabled),
      'lastFetchedAt': serializer.toJson<DateTime?>(lastFetchedAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RssFeedsTableData copyWith({
    String? id,
    String? userId,
    String? name,
    String? url,
    String? description,
    String? iconUrl,
    String? userAgent,
    bool? enabled,
    Value<DateTime?> lastFetchedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RssFeedsTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    url: url ?? this.url,
    description: description ?? this.description,
    iconUrl: iconUrl ?? this.iconUrl,
    userAgent: userAgent ?? this.userAgent,
    enabled: enabled ?? this.enabled,
    lastFetchedAt: lastFetchedAt.present
        ? lastFetchedAt.value
        : this.lastFetchedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RssFeedsTableData copyWithCompanion(RssFeedsTableCompanion data) {
    return RssFeedsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      description: data.description.present
          ? data.description.value
          : this.description,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      userAgent: data.userAgent.present ? data.userAgent.value : this.userAgent,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssFeedsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('userAgent: $userAgent, ')
          ..write('enabled: $enabled, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    url,
    description,
    iconUrl,
    userAgent,
    enabled,
    lastFetchedAt,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssFeedsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.url == this.url &&
          other.description == this.description &&
          other.iconUrl == this.iconUrl &&
          other.userAgent == this.userAgent &&
          other.enabled == this.enabled &&
          other.lastFetchedAt == this.lastFetchedAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RssFeedsTableCompanion extends UpdateCompanion<RssFeedsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> url;
  final Value<String> description;
  final Value<String> iconUrl;
  final Value<String> userAgent;
  final Value<bool> enabled;
  final Value<DateTime?> lastFetchedAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RssFeedsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.description = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.enabled = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssFeedsTableCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String url,
    this.description = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.enabled = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       url = Value(url);
  static Insertable<RssFeedsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? description,
    Expression<String>? iconUrl,
    Expression<String>? userAgent,
    Expression<bool>? enabled,
    Expression<DateTime>? lastFetchedAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (description != null) 'description': description,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (userAgent != null) 'user_agent': userAgent,
      if (enabled != null) 'enabled': enabled,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssFeedsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? url,
    Value<String>? description,
    Value<String>? iconUrl,
    Value<String>? userAgent,
    Value<bool>? enabled,
    Value<DateTime?>? lastFetchedAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RssFeedsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      userAgent: userAgent ?? this.userAgent,
      enabled: enabled ?? this.enabled,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (userAgent.present) {
      map['user_agent'] = Variable<String>(userAgent.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RssFeedsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('userAgent: $userAgent, ')
          ..write('enabled: $enabled, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RssArticlesTableTable extends RssArticlesTable
    with TableInfo<$RssArticlesTableTable, RssArticlesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssArticlesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedIdMeta = const VerificationMeta('feedId');
  @override
  late final GeneratedColumn<String> feedId = GeneratedColumn<String>(
    'feed_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rss_feeds (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedMeta = const VerificationMeta('saved');
  @override
  late final GeneratedColumn<bool> saved = GeneratedColumn<bool>(
    'saved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("saved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _readMeta = const VerificationMeta('read');
  @override
  late final GeneratedColumn<bool> read = GeneratedColumn<bool>(
    'read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    feedId,
    guid,
    title,
    link,
    summary,
    imageUrl,
    author,
    publishedAt,
    saved,
    read,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssArticlesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('feed_id')) {
      context.handle(
        _feedIdMeta,
        feedId.isAcceptableOrUnknown(data['feed_id']!, _feedIdMeta),
      );
    } else if (isInserting) {
      context.missing(_feedIdMeta);
    }
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    } else if (isInserting) {
      context.missing(_linkMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    if (data.containsKey('saved')) {
      context.handle(
        _savedMeta,
        saved.isAcceptableOrUnknown(data['saved']!, _savedMeta),
      );
    }
    if (data.containsKey('read')) {
      context.handle(
        _readMeta,
        read.isAcceptableOrUnknown(data['read']!, _readMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RssArticlesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssArticlesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      feedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_id'],
      )!,
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
      saved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}saved'],
      )!,
      read: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}read'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RssArticlesTableTable createAlias(String alias) {
    return $RssArticlesTableTable(attachedDatabase, alias);
  }
}

class RssArticlesTableData extends DataClass
    implements Insertable<RssArticlesTableData> {
  /// Article id.
  final String id;

  /// Feed id.
  final String feedId;

  /// Feed-provided GUID (or link as fallback).
  final String guid;

  /// Article title.
  final String title;

  /// Link.
  final String link;

  /// Excerpt / description as raw HTML (we strip on render).
  final String summary;

  /// First image URL extracted from media:thumbnail / enclosure / content.
  final String imageUrl;

  /// Article author.
  final String author;

  /// When the article was originally published.
  final DateTime? publishedAt;

  /// Whether the user has bookmarked this article.
  final bool saved;

  /// Whether the user has opened (read) this article.
  final bool read;

  /// When the article was ingested into the local database.
  final DateTime createdAt;
  const RssArticlesTableData({
    required this.id,
    required this.feedId,
    required this.guid,
    required this.title,
    required this.link,
    required this.summary,
    required this.imageUrl,
    required this.author,
    this.publishedAt,
    required this.saved,
    required this.read,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['feed_id'] = Variable<String>(feedId);
    map['guid'] = Variable<String>(guid);
    map['title'] = Variable<String>(title);
    map['link'] = Variable<String>(link);
    map['summary'] = Variable<String>(summary);
    map['image_url'] = Variable<String>(imageUrl);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    map['saved'] = Variable<bool>(saved);
    map['read'] = Variable<bool>(read);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RssArticlesTableCompanion toCompanion(bool nullToAbsent) {
    return RssArticlesTableCompanion(
      id: Value(id),
      feedId: Value(feedId),
      guid: Value(guid),
      title: Value(title),
      link: Value(link),
      summary: Value(summary),
      imageUrl: Value(imageUrl),
      author: Value(author),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
      saved: Value(saved),
      read: Value(read),
      createdAt: Value(createdAt),
    );
  }

  factory RssArticlesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssArticlesTableData(
      id: serializer.fromJson<String>(json['id']),
      feedId: serializer.fromJson<String>(json['feedId']),
      guid: serializer.fromJson<String>(json['guid']),
      title: serializer.fromJson<String>(json['title']),
      link: serializer.fromJson<String>(json['link']),
      summary: serializer.fromJson<String>(json['summary']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      author: serializer.fromJson<String>(json['author']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
      saved: serializer.fromJson<bool>(json['saved']),
      read: serializer.fromJson<bool>(json['read']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'feedId': serializer.toJson<String>(feedId),
      'guid': serializer.toJson<String>(guid),
      'title': serializer.toJson<String>(title),
      'link': serializer.toJson<String>(link),
      'summary': serializer.toJson<String>(summary),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'author': serializer.toJson<String>(author),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
      'saved': serializer.toJson<bool>(saved),
      'read': serializer.toJson<bool>(read),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RssArticlesTableData copyWith({
    String? id,
    String? feedId,
    String? guid,
    String? title,
    String? link,
    String? summary,
    String? imageUrl,
    String? author,
    Value<DateTime?> publishedAt = const Value.absent(),
    bool? saved,
    bool? read,
    DateTime? createdAt,
  }) => RssArticlesTableData(
    id: id ?? this.id,
    feedId: feedId ?? this.feedId,
    guid: guid ?? this.guid,
    title: title ?? this.title,
    link: link ?? this.link,
    summary: summary ?? this.summary,
    imageUrl: imageUrl ?? this.imageUrl,
    author: author ?? this.author,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
    saved: saved ?? this.saved,
    read: read ?? this.read,
    createdAt: createdAt ?? this.createdAt,
  );
  RssArticlesTableData copyWithCompanion(RssArticlesTableCompanion data) {
    return RssArticlesTableData(
      id: data.id.present ? data.id.value : this.id,
      feedId: data.feedId.present ? data.feedId.value : this.feedId,
      guid: data.guid.present ? data.guid.value : this.guid,
      title: data.title.present ? data.title.value : this.title,
      link: data.link.present ? data.link.value : this.link,
      summary: data.summary.present ? data.summary.value : this.summary,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      author: data.author.present ? data.author.value : this.author,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      saved: data.saved.present ? data.saved.value : this.saved,
      read: data.read.present ? data.read.value : this.read,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssArticlesTableData(')
          ..write('id: $id, ')
          ..write('feedId: $feedId, ')
          ..write('guid: $guid, ')
          ..write('title: $title, ')
          ..write('link: $link, ')
          ..write('summary: $summary, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('author: $author, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('saved: $saved, ')
          ..write('read: $read, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    feedId,
    guid,
    title,
    link,
    summary,
    imageUrl,
    author,
    publishedAt,
    saved,
    read,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssArticlesTableData &&
          other.id == this.id &&
          other.feedId == this.feedId &&
          other.guid == this.guid &&
          other.title == this.title &&
          other.link == this.link &&
          other.summary == this.summary &&
          other.imageUrl == this.imageUrl &&
          other.author == this.author &&
          other.publishedAt == this.publishedAt &&
          other.saved == this.saved &&
          other.read == this.read &&
          other.createdAt == this.createdAt);
}

class RssArticlesTableCompanion extends UpdateCompanion<RssArticlesTableData> {
  final Value<String> id;
  final Value<String> feedId;
  final Value<String> guid;
  final Value<String> title;
  final Value<String> link;
  final Value<String> summary;
  final Value<String> imageUrl;
  final Value<String> author;
  final Value<DateTime?> publishedAt;
  final Value<bool> saved;
  final Value<bool> read;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RssArticlesTableCompanion({
    this.id = const Value.absent(),
    this.feedId = const Value.absent(),
    this.guid = const Value.absent(),
    this.title = const Value.absent(),
    this.link = const Value.absent(),
    this.summary = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.author = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.saved = const Value.absent(),
    this.read = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssArticlesTableCompanion.insert({
    required String id,
    required String feedId,
    required String guid,
    required String title,
    required String link,
    this.summary = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.author = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.saved = const Value.absent(),
    this.read = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       feedId = Value(feedId),
       guid = Value(guid),
       title = Value(title),
       link = Value(link);
  static Insertable<RssArticlesTableData> custom({
    Expression<String>? id,
    Expression<String>? feedId,
    Expression<String>? guid,
    Expression<String>? title,
    Expression<String>? link,
    Expression<String>? summary,
    Expression<String>? imageUrl,
    Expression<String>? author,
    Expression<DateTime>? publishedAt,
    Expression<bool>? saved,
    Expression<bool>? read,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (feedId != null) 'feed_id': feedId,
      if (guid != null) 'guid': guid,
      if (title != null) 'title': title,
      if (link != null) 'link': link,
      if (summary != null) 'summary': summary,
      if (imageUrl != null) 'image_url': imageUrl,
      if (author != null) 'author': author,
      if (publishedAt != null) 'published_at': publishedAt,
      if (saved != null) 'saved': saved,
      if (read != null) 'read': read,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssArticlesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? feedId,
    Value<String>? guid,
    Value<String>? title,
    Value<String>? link,
    Value<String>? summary,
    Value<String>? imageUrl,
    Value<String>? author,
    Value<DateTime?>? publishedAt,
    Value<bool>? saved,
    Value<bool>? read,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RssArticlesTableCompanion(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      guid: guid ?? this.guid,
      title: title ?? this.title,
      link: link ?? this.link,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      saved: saved ?? this.saved,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (feedId.present) {
      map['feed_id'] = Variable<String>(feedId.value);
    }
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (saved.present) {
      map['saved'] = Variable<bool>(saved.value);
    }
    if (read.present) {
      map['read'] = Variable<bool>(read.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RssArticlesTableCompanion(')
          ..write('id: $id, ')
          ..write('feedId: $feedId, ')
          ..write('guid: $guid, ')
          ..write('title: $title, ')
          ..write('link: $link, ')
          ..write('summary: $summary, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('author: $author, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('saved: $saved, ')
          ..write('read: $read, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkersTableTable extends WorkersTable
    with TableInfo<$WorkersTableTable, WorkersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capsJsonMeta = const VerificationMeta(
    'capsJson',
  );
  @override
  late final GeneratedColumn<String> capsJson = GeneratedColumn<String>(
    'caps_json',
    aliasedName,
    false,
    check: () => isJsonObject(capsJson),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _credentialRefMeta = const VerificationMeta(
    'credentialRef',
  );
  @override
  late final GeneratedColumn<String> credentialRef = GeneratedColumn<String>(
    'credential_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pairedDeviceIdMeta = const VerificationMeta(
    'pairedDeviceId',
  );
  @override
  late final GeneratedColumn<String> pairedDeviceId = GeneratedColumn<String>(
    'paired_device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES paired_devices (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _protocolVersionMeta = const VerificationMeta(
    'protocolVersion',
  );
  @override
  late final GeneratedColumn<int> protocolVersion = GeneratedColumn<int>(
    'protocol_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(PlatformStoredValues.workerStatus),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('offline'),
  );
  static const VerificationMeta _lastHeartbeatAtMeta = const VerificationMeta(
    'lastHeartbeatAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastHeartbeatAt =
      GeneratedColumn<DateTime>(
        'last_heartbeat_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _registeredByMeta = const VerificationMeta(
    'registeredBy',
  );
  @override
  late final GeneratedColumn<String> registeredBy = GeneratedColumn<String>(
    'registered_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _drainedAtMeta = const VerificationMeta(
    'drainedAt',
  );
  @override
  late final GeneratedColumn<DateTime> drainedAt = GeneratedColumn<DateTime>(
    'drained_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    capsJson,
    platform,
    credentialRef,
    pairedDeviceId,
    protocolVersion,
    status,
    lastHeartbeatAt,
    registeredBy,
    drainedAt,
    revokedAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workers';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('caps_json')) {
      context.handle(
        _capsJsonMeta,
        capsJson.isAcceptableOrUnknown(data['caps_json']!, _capsJsonMeta),
      );
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    }
    if (data.containsKey('credential_ref')) {
      context.handle(
        _credentialRefMeta,
        credentialRef.isAcceptableOrUnknown(
          data['credential_ref']!,
          _credentialRefMeta,
        ),
      );
    }
    if (data.containsKey('paired_device_id')) {
      context.handle(
        _pairedDeviceIdMeta,
        pairedDeviceId.isAcceptableOrUnknown(
          data['paired_device_id']!,
          _pairedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
        _protocolVersionMeta,
        protocolVersion.isAcceptableOrUnknown(
          data['protocol_version']!,
          _protocolVersionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_heartbeat_at')) {
      context.handle(
        _lastHeartbeatAtMeta,
        lastHeartbeatAt.isAcceptableOrUnknown(
          data['last_heartbeat_at']!,
          _lastHeartbeatAtMeta,
        ),
      );
    }
    if (data.containsKey('registered_by')) {
      context.handle(
        _registeredByMeta,
        registeredBy.isAcceptableOrUnknown(
          data['registered_by']!,
          _registeredByMeta,
        ),
      );
    }
    if (data.containsKey('drained_at')) {
      context.handle(
        _drainedAtMeta,
        drainedAt.isAcceptableOrUnknown(data['drained_at']!, _drainedAtMeta),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      capsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caps_json'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      credentialRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_ref'],
      ),
      pairedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paired_device_id'],
      ),
      protocolVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protocol_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastHeartbeatAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_heartbeat_at'],
      ),
      registeredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registered_by'],
      ),
      drainedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}drained_at'],
      ),
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkersTableTable createAlias(String alias) {
    return $WorkersTableTable(attachedDatabase, alias);
  }
}

class WorkersTableData extends DataClass
    implements Insertable<WorkersTableData> {
  /// Unique worker id (UUID v4).
  final String id;

  /// Operator-facing worker name (e.g. "mac-studio").
  final String name;

  /// JSON-encoded `WorkerCapabilities` (OS, arch, cores, RAM, flutter SDK,
  /// sandbox backends, ML/GPU, always-on): a JSON object.
  final String capsJson;

  /// Coarse platform string (`macos`/`linux`/`windows`) for quick display.
  /// An open set: whatever the worker reports.
  final String platform;

  /// Reference to the paired-device credential (never the secret itself).
  final String? credentialRef;

  /// The paired-device row backing this worker (PRD 15), when paired. Cleared
  /// when the device goes: the worker then authenticates as nothing.
  final String? pairedDeviceId;

  /// Wire protocol version the worker handshaked with. A mismatch marks the
  /// worker `incompatible` and withholds leases (spec Clarifications).
  final int protocolVersion;

  /// Lifecycle status: a `WorkerStatus` wire name.
  final String status;

  /// Last heartbeat time (server clock; workers never set server time).
  final DateTime? lastHeartbeatAt;

  /// Principal (user id) that registered this worker. History: cleared if
  /// the user row goes.
  final String? registeredBy;

  /// When the operator put the worker into drain (finish current, take no new).
  final DateTime? drainedAt;

  /// When the worker was revoked (its live session must terminate; no leases).
  final DateTime? revokedAt;

  /// Last error surfaced by/about the worker (for the fleet panel).
  final String? lastError;

  /// Registration time.
  final DateTime createdAt;
  const WorkersTableData({
    required this.id,
    required this.name,
    required this.capsJson,
    required this.platform,
    this.credentialRef,
    this.pairedDeviceId,
    required this.protocolVersion,
    required this.status,
    this.lastHeartbeatAt,
    this.registeredBy,
    this.drainedAt,
    this.revokedAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['caps_json'] = Variable<String>(capsJson);
    map['platform'] = Variable<String>(platform);
    if (!nullToAbsent || credentialRef != null) {
      map['credential_ref'] = Variable<String>(credentialRef);
    }
    if (!nullToAbsent || pairedDeviceId != null) {
      map['paired_device_id'] = Variable<String>(pairedDeviceId);
    }
    map['protocol_version'] = Variable<int>(protocolVersion);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastHeartbeatAt != null) {
      map['last_heartbeat_at'] = Variable<DateTime>(lastHeartbeatAt);
    }
    if (!nullToAbsent || registeredBy != null) {
      map['registered_by'] = Variable<String>(registeredBy);
    }
    if (!nullToAbsent || drainedAt != null) {
      map['drained_at'] = Variable<DateTime>(drainedAt);
    }
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkersTableCompanion toCompanion(bool nullToAbsent) {
    return WorkersTableCompanion(
      id: Value(id),
      name: Value(name),
      capsJson: Value(capsJson),
      platform: Value(platform),
      credentialRef: credentialRef == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialRef),
      pairedDeviceId: pairedDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(pairedDeviceId),
      protocolVersion: Value(protocolVersion),
      status: Value(status),
      lastHeartbeatAt: lastHeartbeatAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHeartbeatAt),
      registeredBy: registeredBy == null && nullToAbsent
          ? const Value.absent()
          : Value(registeredBy),
      drainedAt: drainedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(drainedAt),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory WorkersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkersTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      capsJson: serializer.fromJson<String>(json['capsJson']),
      platform: serializer.fromJson<String>(json['platform']),
      credentialRef: serializer.fromJson<String?>(json['credentialRef']),
      pairedDeviceId: serializer.fromJson<String?>(json['pairedDeviceId']),
      protocolVersion: serializer.fromJson<int>(json['protocolVersion']),
      status: serializer.fromJson<String>(json['status']),
      lastHeartbeatAt: serializer.fromJson<DateTime?>(json['lastHeartbeatAt']),
      registeredBy: serializer.fromJson<String?>(json['registeredBy']),
      drainedAt: serializer.fromJson<DateTime?>(json['drainedAt']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'capsJson': serializer.toJson<String>(capsJson),
      'platform': serializer.toJson<String>(platform),
      'credentialRef': serializer.toJson<String?>(credentialRef),
      'pairedDeviceId': serializer.toJson<String?>(pairedDeviceId),
      'protocolVersion': serializer.toJson<int>(protocolVersion),
      'status': serializer.toJson<String>(status),
      'lastHeartbeatAt': serializer.toJson<DateTime?>(lastHeartbeatAt),
      'registeredBy': serializer.toJson<String?>(registeredBy),
      'drainedAt': serializer.toJson<DateTime?>(drainedAt),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkersTableData copyWith({
    String? id,
    String? name,
    String? capsJson,
    String? platform,
    Value<String?> credentialRef = const Value.absent(),
    Value<String?> pairedDeviceId = const Value.absent(),
    int? protocolVersion,
    String? status,
    Value<DateTime?> lastHeartbeatAt = const Value.absent(),
    Value<String?> registeredBy = const Value.absent(),
    Value<DateTime?> drainedAt = const Value.absent(),
    Value<DateTime?> revokedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => WorkersTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    capsJson: capsJson ?? this.capsJson,
    platform: platform ?? this.platform,
    credentialRef: credentialRef.present
        ? credentialRef.value
        : this.credentialRef,
    pairedDeviceId: pairedDeviceId.present
        ? pairedDeviceId.value
        : this.pairedDeviceId,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    status: status ?? this.status,
    lastHeartbeatAt: lastHeartbeatAt.present
        ? lastHeartbeatAt.value
        : this.lastHeartbeatAt,
    registeredBy: registeredBy.present ? registeredBy.value : this.registeredBy,
    drainedAt: drainedAt.present ? drainedAt.value : this.drainedAt,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  WorkersTableData copyWithCompanion(WorkersTableCompanion data) {
    return WorkersTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      capsJson: data.capsJson.present ? data.capsJson.value : this.capsJson,
      platform: data.platform.present ? data.platform.value : this.platform,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      pairedDeviceId: data.pairedDeviceId.present
          ? data.pairedDeviceId.value
          : this.pairedDeviceId,
      protocolVersion: data.protocolVersion.present
          ? data.protocolVersion.value
          : this.protocolVersion,
      status: data.status.present ? data.status.value : this.status,
      lastHeartbeatAt: data.lastHeartbeatAt.present
          ? data.lastHeartbeatAt.value
          : this.lastHeartbeatAt,
      registeredBy: data.registeredBy.present
          ? data.registeredBy.value
          : this.registeredBy,
      drainedAt: data.drainedAt.present ? data.drainedAt.value : this.drainedAt,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkersTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('capsJson: $capsJson, ')
          ..write('platform: $platform, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('pairedDeviceId: $pairedDeviceId, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('status: $status, ')
          ..write('lastHeartbeatAt: $lastHeartbeatAt, ')
          ..write('registeredBy: $registeredBy, ')
          ..write('drainedAt: $drainedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    capsJson,
    platform,
    credentialRef,
    pairedDeviceId,
    protocolVersion,
    status,
    lastHeartbeatAt,
    registeredBy,
    drainedAt,
    revokedAt,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkersTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.capsJson == this.capsJson &&
          other.platform == this.platform &&
          other.credentialRef == this.credentialRef &&
          other.pairedDeviceId == this.pairedDeviceId &&
          other.protocolVersion == this.protocolVersion &&
          other.status == this.status &&
          other.lastHeartbeatAt == this.lastHeartbeatAt &&
          other.registeredBy == this.registeredBy &&
          other.drainedAt == this.drainedAt &&
          other.revokedAt == this.revokedAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class WorkersTableCompanion extends UpdateCompanion<WorkersTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> capsJson;
  final Value<String> platform;
  final Value<String?> credentialRef;
  final Value<String?> pairedDeviceId;
  final Value<int> protocolVersion;
  final Value<String> status;
  final Value<DateTime?> lastHeartbeatAt;
  final Value<String?> registeredBy;
  final Value<DateTime?> drainedAt;
  final Value<DateTime?> revokedAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WorkersTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.capsJson = const Value.absent(),
    this.platform = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.pairedDeviceId = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.lastHeartbeatAt = const Value.absent(),
    this.registeredBy = const Value.absent(),
    this.drainedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkersTableCompanion.insert({
    required String id,
    required String name,
    this.capsJson = const Value.absent(),
    this.platform = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.pairedDeviceId = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.lastHeartbeatAt = const Value.absent(),
    this.registeredBy = const Value.absent(),
    this.drainedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<WorkersTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? capsJson,
    Expression<String>? platform,
    Expression<String>? credentialRef,
    Expression<String>? pairedDeviceId,
    Expression<int>? protocolVersion,
    Expression<String>? status,
    Expression<DateTime>? lastHeartbeatAt,
    Expression<String>? registeredBy,
    Expression<DateTime>? drainedAt,
    Expression<DateTime>? revokedAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (capsJson != null) 'caps_json': capsJson,
      if (platform != null) 'platform': platform,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (pairedDeviceId != null) 'paired_device_id': pairedDeviceId,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (status != null) 'status': status,
      if (lastHeartbeatAt != null) 'last_heartbeat_at': lastHeartbeatAt,
      if (registeredBy != null) 'registered_by': registeredBy,
      if (drainedAt != null) 'drained_at': drainedAt,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? capsJson,
    Value<String>? platform,
    Value<String?>? credentialRef,
    Value<String?>? pairedDeviceId,
    Value<int>? protocolVersion,
    Value<String>? status,
    Value<DateTime?>? lastHeartbeatAt,
    Value<String?>? registeredBy,
    Value<DateTime?>? drainedAt,
    Value<DateTime?>? revokedAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WorkersTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      capsJson: capsJson ?? this.capsJson,
      platform: platform ?? this.platform,
      credentialRef: credentialRef ?? this.credentialRef,
      pairedDeviceId: pairedDeviceId ?? this.pairedDeviceId,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      status: status ?? this.status,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      registeredBy: registeredBy ?? this.registeredBy,
      drainedAt: drainedAt ?? this.drainedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (capsJson.present) {
      map['caps_json'] = Variable<String>(capsJson.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (credentialRef.present) {
      map['credential_ref'] = Variable<String>(credentialRef.value);
    }
    if (pairedDeviceId.present) {
      map['paired_device_id'] = Variable<String>(pairedDeviceId.value);
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<int>(protocolVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastHeartbeatAt.present) {
      map['last_heartbeat_at'] = Variable<DateTime>(lastHeartbeatAt.value);
    }
    if (registeredBy.present) {
      map['registered_by'] = Variable<String>(registeredBy.value);
    }
    if (drainedAt.present) {
      map['drained_at'] = Variable<DateTime>(drainedAt.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkersTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('capsJson: $capsJson, ')
          ..write('platform: $platform, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('pairedDeviceId: $pairedDeviceId, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('status: $status, ')
          ..write('lastHeartbeatAt: $lastHeartbeatAt, ')
          ..write('registeredBy: $registeredBy, ')
          ..write('drainedAt: $drainedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobsTableTable extends JobsTable
    with TableInfo<$JobsTableTable, JobsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(PlatformStoredValues.jobKind),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _specJsonMeta = const VerificationMeta(
    'specJson',
  );
  @override
  late final GeneratedColumn<String> specJson = GeneratedColumn<String>(
    'spec_json',
    aliasedName,
    false,
    check: () => isJsonObject(specJson),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _requiredCapsJsonMeta = const VerificationMeta(
    'requiredCapsJson',
  );
  @override
  late final GeneratedColumn<String> requiredCapsJson = GeneratedColumn<String>(
    'required_caps_json',
    aliasedName,
    false,
    check: () => isJsonArray(requiredCapsJson),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _preferredCapsJsonMeta = const VerificationMeta(
    'preferredCapsJson',
  );
  @override
  late final GeneratedColumn<String> preferredCapsJson =
      GeneratedColumn<String>(
        'preferred_caps_json',
        aliasedName,
        false,
        check: () => isJsonArray(preferredCapsJson),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(PlatformStoredValues.jobStatus),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workers (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _pinnedWorkerIdMeta = const VerificationMeta(
    'pinnedWorkerId',
  );
  @override
  late final GeneratedColumn<String> pinnedWorkerId = GeneratedColumn<String>(
    'pinned_worker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leaseExpiresAtMeta = const VerificationMeta(
    'leaseExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> leaseExpiresAt =
      GeneratedColumn<DateTime>(
        'lease_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _submittedByMeta = const VerificationMeta(
    'submittedBy',
  );
  @override
  late final GeneratedColumn<String> submittedBy = GeneratedColumn<String>(
    'submitted_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _costMicrosMeta = const VerificationMeta(
    'costMicros',
  );
  @override
  late final GeneratedColumn<int> costMicros = GeneratedColumn<int>(
    'cost_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxAttemptsMeta = const VerificationMeta(
    'maxAttempts',
  );
  @override
  late final GeneratedColumn<int> maxAttempts = GeneratedColumn<int>(
    'max_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastAckedSeqMeta = const VerificationMeta(
    'lastAckedSeq',
  );
  @override
  late final GeneratedColumn<int> lastAckedSeq = GeneratedColumn<int>(
    'last_acked_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    true,
    check: () => isJson(resultJson),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _leasedAtMeta = const VerificationMeta(
    'leasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> leasedAt = GeneratedColumn<DateTime>(
    'leased_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    kind,
    specJson,
    requiredCapsJson,
    preferredCapsJson,
    status,
    workerId,
    pinnedWorkerId,
    leaseExpiresAt,
    priority,
    submittedBy,
    costMicros,
    attempts,
    maxAttempts,
    lastAckedSeq,
    resultJson,
    error,
    agentId,
    conversationId,
    createdAt,
    leasedAt,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('spec_json')) {
      context.handle(
        _specJsonMeta,
        specJson.isAcceptableOrUnknown(data['spec_json']!, _specJsonMeta),
      );
    }
    if (data.containsKey('required_caps_json')) {
      context.handle(
        _requiredCapsJsonMeta,
        requiredCapsJson.isAcceptableOrUnknown(
          data['required_caps_json']!,
          _requiredCapsJsonMeta,
        ),
      );
    }
    if (data.containsKey('preferred_caps_json')) {
      context.handle(
        _preferredCapsJsonMeta,
        preferredCapsJson.isAcceptableOrUnknown(
          data['preferred_caps_json']!,
          _preferredCapsJsonMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    }
    if (data.containsKey('pinned_worker_id')) {
      context.handle(
        _pinnedWorkerIdMeta,
        pinnedWorkerId.isAcceptableOrUnknown(
          data['pinned_worker_id']!,
          _pinnedWorkerIdMeta,
        ),
      );
    }
    if (data.containsKey('lease_expires_at')) {
      context.handle(
        _leaseExpiresAtMeta,
        leaseExpiresAt.isAcceptableOrUnknown(
          data['lease_expires_at']!,
          _leaseExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('submitted_by')) {
      context.handle(
        _submittedByMeta,
        submittedBy.isAcceptableOrUnknown(
          data['submitted_by']!,
          _submittedByMeta,
        ),
      );
    }
    if (data.containsKey('cost_micros')) {
      context.handle(
        _costMicrosMeta,
        costMicros.isAcceptableOrUnknown(data['cost_micros']!, _costMicrosMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('max_attempts')) {
      context.handle(
        _maxAttemptsMeta,
        maxAttempts.isAcceptableOrUnknown(
          data['max_attempts']!,
          _maxAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_acked_seq')) {
      context.handle(
        _lastAckedSeqMeta,
        lastAckedSeq.isAcceptableOrUnknown(
          data['last_acked_seq']!,
          _lastAckedSeqMeta,
        ),
      );
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('leased_at')) {
      context.handle(
        _leasedAtMeta,
        leasedAt.isAcceptableOrUnknown(data['leased_at']!, _leasedAtMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      specJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spec_json'],
      )!,
      requiredCapsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}required_caps_json'],
      )!,
      preferredCapsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_caps_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      ),
      pinnedWorkerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinned_worker_id'],
      ),
      leaseExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lease_expires_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      submittedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submitted_by'],
      ),
      costMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_micros'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      maxAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_attempts'],
      )!,
      lastAckedSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_acked_seq'],
      )!,
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      ),
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      leasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}leased_at'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $JobsTableTable createAlias(String alias) {
    return $JobsTableTable(attachedDatabase, alias);
  }
}

class JobsTableData extends DataClass implements Insertable<JobsTableData> {
  /// Unique job id (UUID v4).
  final String id;

  /// Workspace scope; a job is part of its workspace.
  final String workspaceId;

  /// Job kind: a `JobKind` wire name.
  final String kind;

  /// JSON-encoded `JobSpec` payload (kind-specific): a JSON object.
  final String specJson;

  /// JSON array of required capability keys (must all be present on a worker).
  final String requiredCapsJson;

  /// JSON array of preferred capability keys (break ties / prefer placement).
  final String preferredCapsJson;

  /// Status: a `JobStatus` wire name.
  final String status;

  /// The worker currently holding the lease (null while queued). Cleared if
  /// the worker row goes: the reaper then sees a lease nobody holds.
  final String? workerId;

  /// An explicit pin: this job MUST run on this worker id (deterministic).
  /// No foreign key: a pin may name a worker that is not registered (yet, or
  /// any more); the scheduler then reports it unavailable.
  final String? pinnedWorkerId;

  /// Lease expiry (server clock). A worker that vanishes has its lease reaped
  /// after this instant.
  final DateTime? leaseExpiresAt;

  /// Scheduling priority (higher runs first within a workspace).
  final int priority;

  /// Principal (user id) that submitted the job. History: cleared if the user
  /// row goes.
  final String? submittedBy;

  /// Metered worker cost in micro-dollars (token cost stays the billable
  /// cost).
  final int costMicros;

  /// Attempt count (incremented on each lease → reap/retry cycle).
  final int attempts;

  /// Maximum attempts before the job is surfaced as failed.
  final int maxAttempts;

  /// Last event sequence the server acked from the worker (reconnect replay).
  final int lastAckedSeq;

  /// JSON-encoded result payload (artifact refs, branch, grade) when done.
  final String? resultJson;

  /// Failure reason when `failed`.
  final String? error;

  /// Correlated agent run / conversation this job drives, when applicable.
  /// No foreign key: agents live in the workspace's own database.
  final String? agentId;

  /// Correlated conversation (space) id, when applicable. No foreign key:
  /// conversations live in the workspace's own database.
  final String? conversationId;

  /// Submission time.
  final DateTime createdAt;

  /// When the job was leased to a worker.
  final DateTime? leasedAt;

  /// When the worker reported it started executing.
  final DateTime? startedAt;

  /// When the job reached a terminal state.
  final DateTime? finishedAt;
  const JobsTableData({
    required this.id,
    required this.workspaceId,
    required this.kind,
    required this.specJson,
    required this.requiredCapsJson,
    required this.preferredCapsJson,
    required this.status,
    this.workerId,
    this.pinnedWorkerId,
    this.leaseExpiresAt,
    required this.priority,
    this.submittedBy,
    required this.costMicros,
    required this.attempts,
    required this.maxAttempts,
    required this.lastAckedSeq,
    this.resultJson,
    this.error,
    this.agentId,
    this.conversationId,
    required this.createdAt,
    this.leasedAt,
    this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['kind'] = Variable<String>(kind);
    map['spec_json'] = Variable<String>(specJson);
    map['required_caps_json'] = Variable<String>(requiredCapsJson);
    map['preferred_caps_json'] = Variable<String>(preferredCapsJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || workerId != null) {
      map['worker_id'] = Variable<String>(workerId);
    }
    if (!nullToAbsent || pinnedWorkerId != null) {
      map['pinned_worker_id'] = Variable<String>(pinnedWorkerId);
    }
    if (!nullToAbsent || leaseExpiresAt != null) {
      map['lease_expires_at'] = Variable<DateTime>(leaseExpiresAt);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || submittedBy != null) {
      map['submitted_by'] = Variable<String>(submittedBy);
    }
    map['cost_micros'] = Variable<int>(costMicros);
    map['attempts'] = Variable<int>(attempts);
    map['max_attempts'] = Variable<int>(maxAttempts);
    map['last_acked_seq'] = Variable<int>(lastAckedSeq);
    if (!nullToAbsent || resultJson != null) {
      map['result_json'] = Variable<String>(resultJson);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || agentId != null) {
      map['agent_id'] = Variable<String>(agentId);
    }
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || leasedAt != null) {
      map['leased_at'] = Variable<DateTime>(leasedAt);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  JobsTableCompanion toCompanion(bool nullToAbsent) {
    return JobsTableCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      kind: Value(kind),
      specJson: Value(specJson),
      requiredCapsJson: Value(requiredCapsJson),
      preferredCapsJson: Value(preferredCapsJson),
      status: Value(status),
      workerId: workerId == null && nullToAbsent
          ? const Value.absent()
          : Value(workerId),
      pinnedWorkerId: pinnedWorkerId == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedWorkerId),
      leaseExpiresAt: leaseExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseExpiresAt),
      priority: Value(priority),
      submittedBy: submittedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedBy),
      costMicros: Value(costMicros),
      attempts: Value(attempts),
      maxAttempts: Value(maxAttempts),
      lastAckedSeq: Value(lastAckedSeq),
      resultJson: resultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(resultJson),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      agentId: agentId == null && nullToAbsent
          ? const Value.absent()
          : Value(agentId),
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      createdAt: Value(createdAt),
      leasedAt: leasedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leasedAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory JobsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobsTableData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      kind: serializer.fromJson<String>(json['kind']),
      specJson: serializer.fromJson<String>(json['specJson']),
      requiredCapsJson: serializer.fromJson<String>(json['requiredCapsJson']),
      preferredCapsJson: serializer.fromJson<String>(json['preferredCapsJson']),
      status: serializer.fromJson<String>(json['status']),
      workerId: serializer.fromJson<String?>(json['workerId']),
      pinnedWorkerId: serializer.fromJson<String?>(json['pinnedWorkerId']),
      leaseExpiresAt: serializer.fromJson<DateTime?>(json['leaseExpiresAt']),
      priority: serializer.fromJson<int>(json['priority']),
      submittedBy: serializer.fromJson<String?>(json['submittedBy']),
      costMicros: serializer.fromJson<int>(json['costMicros']),
      attempts: serializer.fromJson<int>(json['attempts']),
      maxAttempts: serializer.fromJson<int>(json['maxAttempts']),
      lastAckedSeq: serializer.fromJson<int>(json['lastAckedSeq']),
      resultJson: serializer.fromJson<String?>(json['resultJson']),
      error: serializer.fromJson<String?>(json['error']),
      agentId: serializer.fromJson<String?>(json['agentId']),
      conversationId: serializer.fromJson<String?>(json['conversationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      leasedAt: serializer.fromJson<DateTime?>(json['leasedAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'kind': serializer.toJson<String>(kind),
      'specJson': serializer.toJson<String>(specJson),
      'requiredCapsJson': serializer.toJson<String>(requiredCapsJson),
      'preferredCapsJson': serializer.toJson<String>(preferredCapsJson),
      'status': serializer.toJson<String>(status),
      'workerId': serializer.toJson<String?>(workerId),
      'pinnedWorkerId': serializer.toJson<String?>(pinnedWorkerId),
      'leaseExpiresAt': serializer.toJson<DateTime?>(leaseExpiresAt),
      'priority': serializer.toJson<int>(priority),
      'submittedBy': serializer.toJson<String?>(submittedBy),
      'costMicros': serializer.toJson<int>(costMicros),
      'attempts': serializer.toJson<int>(attempts),
      'maxAttempts': serializer.toJson<int>(maxAttempts),
      'lastAckedSeq': serializer.toJson<int>(lastAckedSeq),
      'resultJson': serializer.toJson<String?>(resultJson),
      'error': serializer.toJson<String?>(error),
      'agentId': serializer.toJson<String?>(agentId),
      'conversationId': serializer.toJson<String?>(conversationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'leasedAt': serializer.toJson<DateTime?>(leasedAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  JobsTableData copyWith({
    String? id,
    String? workspaceId,
    String? kind,
    String? specJson,
    String? requiredCapsJson,
    String? preferredCapsJson,
    String? status,
    Value<String?> workerId = const Value.absent(),
    Value<String?> pinnedWorkerId = const Value.absent(),
    Value<DateTime?> leaseExpiresAt = const Value.absent(),
    int? priority,
    Value<String?> submittedBy = const Value.absent(),
    int? costMicros,
    int? attempts,
    int? maxAttempts,
    int? lastAckedSeq,
    Value<String?> resultJson = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<String?> agentId = const Value.absent(),
    Value<String?> conversationId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> leasedAt = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => JobsTableData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    kind: kind ?? this.kind,
    specJson: specJson ?? this.specJson,
    requiredCapsJson: requiredCapsJson ?? this.requiredCapsJson,
    preferredCapsJson: preferredCapsJson ?? this.preferredCapsJson,
    status: status ?? this.status,
    workerId: workerId.present ? workerId.value : this.workerId,
    pinnedWorkerId: pinnedWorkerId.present
        ? pinnedWorkerId.value
        : this.pinnedWorkerId,
    leaseExpiresAt: leaseExpiresAt.present
        ? leaseExpiresAt.value
        : this.leaseExpiresAt,
    priority: priority ?? this.priority,
    submittedBy: submittedBy.present ? submittedBy.value : this.submittedBy,
    costMicros: costMicros ?? this.costMicros,
    attempts: attempts ?? this.attempts,
    maxAttempts: maxAttempts ?? this.maxAttempts,
    lastAckedSeq: lastAckedSeq ?? this.lastAckedSeq,
    resultJson: resultJson.present ? resultJson.value : this.resultJson,
    error: error.present ? error.value : this.error,
    agentId: agentId.present ? agentId.value : this.agentId,
    conversationId: conversationId.present
        ? conversationId.value
        : this.conversationId,
    createdAt: createdAt ?? this.createdAt,
    leasedAt: leasedAt.present ? leasedAt.value : this.leasedAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  JobsTableData copyWithCompanion(JobsTableCompanion data) {
    return JobsTableData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      specJson: data.specJson.present ? data.specJson.value : this.specJson,
      requiredCapsJson: data.requiredCapsJson.present
          ? data.requiredCapsJson.value
          : this.requiredCapsJson,
      preferredCapsJson: data.preferredCapsJson.present
          ? data.preferredCapsJson.value
          : this.preferredCapsJson,
      status: data.status.present ? data.status.value : this.status,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      pinnedWorkerId: data.pinnedWorkerId.present
          ? data.pinnedWorkerId.value
          : this.pinnedWorkerId,
      leaseExpiresAt: data.leaseExpiresAt.present
          ? data.leaseExpiresAt.value
          : this.leaseExpiresAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      submittedBy: data.submittedBy.present
          ? data.submittedBy.value
          : this.submittedBy,
      costMicros: data.costMicros.present
          ? data.costMicros.value
          : this.costMicros,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      maxAttempts: data.maxAttempts.present
          ? data.maxAttempts.value
          : this.maxAttempts,
      lastAckedSeq: data.lastAckedSeq.present
          ? data.lastAckedSeq.value
          : this.lastAckedSeq,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      error: data.error.present ? data.error.value : this.error,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      leasedAt: data.leasedAt.present ? data.leasedAt.value : this.leasedAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobsTableData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('kind: $kind, ')
          ..write('specJson: $specJson, ')
          ..write('requiredCapsJson: $requiredCapsJson, ')
          ..write('preferredCapsJson: $preferredCapsJson, ')
          ..write('status: $status, ')
          ..write('workerId: $workerId, ')
          ..write('pinnedWorkerId: $pinnedWorkerId, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('priority: $priority, ')
          ..write('submittedBy: $submittedBy, ')
          ..write('costMicros: $costMicros, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('lastAckedSeq: $lastAckedSeq, ')
          ..write('resultJson: $resultJson, ')
          ..write('error: $error, ')
          ..write('agentId: $agentId, ')
          ..write('conversationId: $conversationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('leasedAt: $leasedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    kind,
    specJson,
    requiredCapsJson,
    preferredCapsJson,
    status,
    workerId,
    pinnedWorkerId,
    leaseExpiresAt,
    priority,
    submittedBy,
    costMicros,
    attempts,
    maxAttempts,
    lastAckedSeq,
    resultJson,
    error,
    agentId,
    conversationId,
    createdAt,
    leasedAt,
    startedAt,
    finishedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobsTableData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.kind == this.kind &&
          other.specJson == this.specJson &&
          other.requiredCapsJson == this.requiredCapsJson &&
          other.preferredCapsJson == this.preferredCapsJson &&
          other.status == this.status &&
          other.workerId == this.workerId &&
          other.pinnedWorkerId == this.pinnedWorkerId &&
          other.leaseExpiresAt == this.leaseExpiresAt &&
          other.priority == this.priority &&
          other.submittedBy == this.submittedBy &&
          other.costMicros == this.costMicros &&
          other.attempts == this.attempts &&
          other.maxAttempts == this.maxAttempts &&
          other.lastAckedSeq == this.lastAckedSeq &&
          other.resultJson == this.resultJson &&
          other.error == this.error &&
          other.agentId == this.agentId &&
          other.conversationId == this.conversationId &&
          other.createdAt == this.createdAt &&
          other.leasedAt == this.leasedAt &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class JobsTableCompanion extends UpdateCompanion<JobsTableData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> kind;
  final Value<String> specJson;
  final Value<String> requiredCapsJson;
  final Value<String> preferredCapsJson;
  final Value<String> status;
  final Value<String?> workerId;
  final Value<String?> pinnedWorkerId;
  final Value<DateTime?> leaseExpiresAt;
  final Value<int> priority;
  final Value<String?> submittedBy;
  final Value<int> costMicros;
  final Value<int> attempts;
  final Value<int> maxAttempts;
  final Value<int> lastAckedSeq;
  final Value<String?> resultJson;
  final Value<String?> error;
  final Value<String?> agentId;
  final Value<String?> conversationId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> leasedAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const JobsTableCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.specJson = const Value.absent(),
    this.requiredCapsJson = const Value.absent(),
    this.preferredCapsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.workerId = const Value.absent(),
    this.pinnedWorkerId = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.submittedBy = const Value.absent(),
    this.costMicros = const Value.absent(),
    this.attempts = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.lastAckedSeq = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.error = const Value.absent(),
    this.agentId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.leasedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobsTableCompanion.insert({
    required String id,
    required String workspaceId,
    required String kind,
    this.specJson = const Value.absent(),
    this.requiredCapsJson = const Value.absent(),
    this.preferredCapsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.workerId = const Value.absent(),
    this.pinnedWorkerId = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.submittedBy = const Value.absent(),
    this.costMicros = const Value.absent(),
    this.attempts = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.lastAckedSeq = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.error = const Value.absent(),
    this.agentId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.leasedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       kind = Value(kind);
  static Insertable<JobsTableData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? kind,
    Expression<String>? specJson,
    Expression<String>? requiredCapsJson,
    Expression<String>? preferredCapsJson,
    Expression<String>? status,
    Expression<String>? workerId,
    Expression<String>? pinnedWorkerId,
    Expression<DateTime>? leaseExpiresAt,
    Expression<int>? priority,
    Expression<String>? submittedBy,
    Expression<int>? costMicros,
    Expression<int>? attempts,
    Expression<int>? maxAttempts,
    Expression<int>? lastAckedSeq,
    Expression<String>? resultJson,
    Expression<String>? error,
    Expression<String>? agentId,
    Expression<String>? conversationId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? leasedAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (kind != null) 'kind': kind,
      if (specJson != null) 'spec_json': specJson,
      if (requiredCapsJson != null) 'required_caps_json': requiredCapsJson,
      if (preferredCapsJson != null) 'preferred_caps_json': preferredCapsJson,
      if (status != null) 'status': status,
      if (workerId != null) 'worker_id': workerId,
      if (pinnedWorkerId != null) 'pinned_worker_id': pinnedWorkerId,
      if (leaseExpiresAt != null) 'lease_expires_at': leaseExpiresAt,
      if (priority != null) 'priority': priority,
      if (submittedBy != null) 'submitted_by': submittedBy,
      if (costMicros != null) 'cost_micros': costMicros,
      if (attempts != null) 'attempts': attempts,
      if (maxAttempts != null) 'max_attempts': maxAttempts,
      if (lastAckedSeq != null) 'last_acked_seq': lastAckedSeq,
      if (resultJson != null) 'result_json': resultJson,
      if (error != null) 'error': error,
      if (agentId != null) 'agent_id': agentId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (createdAt != null) 'created_at': createdAt,
      if (leasedAt != null) 'leased_at': leasedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? kind,
    Value<String>? specJson,
    Value<String>? requiredCapsJson,
    Value<String>? preferredCapsJson,
    Value<String>? status,
    Value<String?>? workerId,
    Value<String?>? pinnedWorkerId,
    Value<DateTime?>? leaseExpiresAt,
    Value<int>? priority,
    Value<String?>? submittedBy,
    Value<int>? costMicros,
    Value<int>? attempts,
    Value<int>? maxAttempts,
    Value<int>? lastAckedSeq,
    Value<String?>? resultJson,
    Value<String?>? error,
    Value<String?>? agentId,
    Value<String?>? conversationId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? leasedAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return JobsTableCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      kind: kind ?? this.kind,
      specJson: specJson ?? this.specJson,
      requiredCapsJson: requiredCapsJson ?? this.requiredCapsJson,
      preferredCapsJson: preferredCapsJson ?? this.preferredCapsJson,
      status: status ?? this.status,
      workerId: workerId ?? this.workerId,
      pinnedWorkerId: pinnedWorkerId ?? this.pinnedWorkerId,
      leaseExpiresAt: leaseExpiresAt ?? this.leaseExpiresAt,
      priority: priority ?? this.priority,
      submittedBy: submittedBy ?? this.submittedBy,
      costMicros: costMicros ?? this.costMicros,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lastAckedSeq: lastAckedSeq ?? this.lastAckedSeq,
      resultJson: resultJson ?? this.resultJson,
      error: error ?? this.error,
      agentId: agentId ?? this.agentId,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
      leasedAt: leasedAt ?? this.leasedAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (specJson.present) {
      map['spec_json'] = Variable<String>(specJson.value);
    }
    if (requiredCapsJson.present) {
      map['required_caps_json'] = Variable<String>(requiredCapsJson.value);
    }
    if (preferredCapsJson.present) {
      map['preferred_caps_json'] = Variable<String>(preferredCapsJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (pinnedWorkerId.present) {
      map['pinned_worker_id'] = Variable<String>(pinnedWorkerId.value);
    }
    if (leaseExpiresAt.present) {
      map['lease_expires_at'] = Variable<DateTime>(leaseExpiresAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (submittedBy.present) {
      map['submitted_by'] = Variable<String>(submittedBy.value);
    }
    if (costMicros.present) {
      map['cost_micros'] = Variable<int>(costMicros.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (maxAttempts.present) {
      map['max_attempts'] = Variable<int>(maxAttempts.value);
    }
    if (lastAckedSeq.present) {
      map['last_acked_seq'] = Variable<int>(lastAckedSeq.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (leasedAt.present) {
      map['leased_at'] = Variable<DateTime>(leasedAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsTableCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('kind: $kind, ')
          ..write('specJson: $specJson, ')
          ..write('requiredCapsJson: $requiredCapsJson, ')
          ..write('preferredCapsJson: $preferredCapsJson, ')
          ..write('status: $status, ')
          ..write('workerId: $workerId, ')
          ..write('pinnedWorkerId: $pinnedWorkerId, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('priority: $priority, ')
          ..write('submittedBy: $submittedBy, ')
          ..write('costMicros: $costMicros, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('lastAckedSeq: $lastAckedSeq, ')
          ..write('resultJson: $resultJson, ')
          ..write('error: $error, ')
          ..write('agentId: $agentId, ')
          ..write('conversationId: $conversationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('leasedAt: $leasedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlacementLogTableTable extends PlacementLogTable
    with TableInfo<$PlacementLogTableTable, PlacementLogTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacementLogTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES jobs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workers (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _decisionMeta = const VerificationMeta(
    'decision',
  );
  @override
  late final GeneratedColumn<String> decision = GeneratedColumn<String>(
    'decision',
    aliasedName,
    false,
    check: () => decision.isIn(PlatformStoredValues.placementCode),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    jobId,
    workerId,
    decision,
    reason,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'placement_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlacementLogTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    }
    if (data.containsKey('decision')) {
      context.handle(
        _decisionMeta,
        decision.isAcceptableOrUnknown(data['decision']!, _decisionMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlacementLogTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlacementLogTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      ),
      decision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decision'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlacementLogTableTable createAlias(String alias) {
    return $PlacementLogTableTable(attachedDatabase, alias);
  }
}

class PlacementLogTableData extends DataClass
    implements Insertable<PlacementLogTableData> {
  /// Unique row id (UUID v4).
  final String id;

  /// Workspace scope (matches the job); goes with its workspace.
  final String workspaceId;

  /// The job this decision is about; a decision about a job that is gone is
  /// history of nothing, so it goes with the job.
  final String jobId;

  /// The chosen worker id, or null when the decision was "stay queued".
  /// History: cleared if the worker row goes.
  final String? workerId;

  /// Machine-parseable decision code: a `PlacementCode` wire name.
  final String decision;

  /// Human-readable explanation ("ran on mac-studio — required flutter;
  /// vps-1 lacked it").
  final String reason;

  /// Decision time.
  final DateTime createdAt;
  const PlacementLogTableData({
    required this.id,
    required this.workspaceId,
    required this.jobId,
    this.workerId,
    required this.decision,
    required this.reason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['job_id'] = Variable<String>(jobId);
    if (!nullToAbsent || workerId != null) {
      map['worker_id'] = Variable<String>(workerId);
    }
    map['decision'] = Variable<String>(decision);
    map['reason'] = Variable<String>(reason);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlacementLogTableCompanion toCompanion(bool nullToAbsent) {
    return PlacementLogTableCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      jobId: Value(jobId),
      workerId: workerId == null && nullToAbsent
          ? const Value.absent()
          : Value(workerId),
      decision: Value(decision),
      reason: Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory PlacementLogTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlacementLogTableData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      jobId: serializer.fromJson<String>(json['jobId']),
      workerId: serializer.fromJson<String?>(json['workerId']),
      decision: serializer.fromJson<String>(json['decision']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'jobId': serializer.toJson<String>(jobId),
      'workerId': serializer.toJson<String?>(workerId),
      'decision': serializer.toJson<String>(decision),
      'reason': serializer.toJson<String>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlacementLogTableData copyWith({
    String? id,
    String? workspaceId,
    String? jobId,
    Value<String?> workerId = const Value.absent(),
    String? decision,
    String? reason,
    DateTime? createdAt,
  }) => PlacementLogTableData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    jobId: jobId ?? this.jobId,
    workerId: workerId.present ? workerId.value : this.workerId,
    decision: decision ?? this.decision,
    reason: reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
  );
  PlacementLogTableData copyWithCompanion(PlacementLogTableCompanion data) {
    return PlacementLogTableData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      decision: data.decision.present ? data.decision.value : this.decision,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlacementLogTableData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('jobId: $jobId, ')
          ..write('workerId: $workerId, ')
          ..write('decision: $decision, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    jobId,
    workerId,
    decision,
    reason,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlacementLogTableData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.jobId == this.jobId &&
          other.workerId == this.workerId &&
          other.decision == this.decision &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class PlacementLogTableCompanion
    extends UpdateCompanion<PlacementLogTableData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> jobId;
  final Value<String?> workerId;
  final Value<String> decision;
  final Value<String> reason;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlacementLogTableCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.workerId = const Value.absent(),
    this.decision = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlacementLogTableCompanion.insert({
    required String id,
    required String workspaceId,
    required String jobId,
    this.workerId = const Value.absent(),
    this.decision = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       jobId = Value(jobId);
  static Insertable<PlacementLogTableData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? jobId,
    Expression<String>? workerId,
    Expression<String>? decision,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (jobId != null) 'job_id': jobId,
      if (workerId != null) 'worker_id': workerId,
      if (decision != null) 'decision': decision,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlacementLogTableCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? jobId,
    Value<String?>? workerId,
    Value<String>? decision,
    Value<String>? reason,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlacementLogTableCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      decision: decision ?? this.decision,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (decision.present) {
      map['decision'] = Variable<String>(decision.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacementLogTableCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('jobId: $jobId, ')
          ..write('workerId: $workerId, ')
          ..write('decision: $decision, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkspaceRoutesTableTable extends WorkspaceRoutesTable
    with TableInfo<$WorkspaceRoutesTableTable, WorkspaceRoutesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspaceRoutesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(PlatformStoredValues.workspaceRouteKind),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyHashMeta = const VerificationMeta(
    'keyHash',
  );
  @override
  late final GeneratedColumn<String> keyHash = GeneratedColumn<String>(
    'key_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, keyHash, workspaceId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceRoutesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('key_hash')) {
      context.handle(
        _keyHashMeta,
        keyHash.isAcceptableOrUnknown(data['key_hash']!, _keyHashMeta),
      );
    } else if (isInserting) {
      context.missing(_keyHashMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, keyHash};
  @override
  WorkspaceRoutesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceRoutesTableData(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      keyHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_hash'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkspaceRoutesTableTable createAlias(String alias) {
    return $WorkspaceRoutesTableTable(attachedDatabase, alias);
  }
}

class WorkspaceRoutesTableData extends DataClass
    implements Insertable<WorkspaceRoutesTableData> {
  /// The kind of key being routed: a [WorkspaceRouteKind] wire name.
  final String kind;

  /// The key itself: a hash for secrets, the raw id for opaque ids. Never a
  /// plaintext secret.
  final String keyHash;

  /// The workspace that owns the keyed entity; the route goes with it.
  final String workspaceId;

  /// When the route was recorded.
  final DateTime createdAt;
  const WorkspaceRoutesTableData({
    required this.kind,
    required this.keyHash,
    required this.workspaceId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['key_hash'] = Variable<String>(keyHash);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkspaceRoutesTableCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceRoutesTableCompanion(
      kind: Value(kind),
      keyHash: Value(keyHash),
      workspaceId: Value(workspaceId),
      createdAt: Value(createdAt),
    );
  }

  factory WorkspaceRoutesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceRoutesTableData(
      kind: serializer.fromJson<String>(json['kind']),
      keyHash: serializer.fromJson<String>(json['keyHash']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'keyHash': serializer.toJson<String>(keyHash),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkspaceRoutesTableData copyWith({
    String? kind,
    String? keyHash,
    String? workspaceId,
    DateTime? createdAt,
  }) => WorkspaceRoutesTableData(
    kind: kind ?? this.kind,
    keyHash: keyHash ?? this.keyHash,
    workspaceId: workspaceId ?? this.workspaceId,
    createdAt: createdAt ?? this.createdAt,
  );
  WorkspaceRoutesTableData copyWithCompanion(
    WorkspaceRoutesTableCompanion data,
  ) {
    return WorkspaceRoutesTableData(
      kind: data.kind.present ? data.kind.value : this.kind,
      keyHash: data.keyHash.present ? data.keyHash.value : this.keyHash,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRoutesTableData(')
          ..write('kind: $kind, ')
          ..write('keyHash: $keyHash, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, keyHash, workspaceId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceRoutesTableData &&
          other.kind == this.kind &&
          other.keyHash == this.keyHash &&
          other.workspaceId == this.workspaceId &&
          other.createdAt == this.createdAt);
}

class WorkspaceRoutesTableCompanion
    extends UpdateCompanion<WorkspaceRoutesTableData> {
  final Value<String> kind;
  final Value<String> keyHash;
  final Value<String> workspaceId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WorkspaceRoutesTableCompanion({
    this.kind = const Value.absent(),
    this.keyHash = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceRoutesTableCompanion.insert({
    required String kind,
    required String keyHash,
    required String workspaceId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       keyHash = Value(keyHash),
       workspaceId = Value(workspaceId);
  static Insertable<WorkspaceRoutesTableData> custom({
    Expression<String>? kind,
    Expression<String>? keyHash,
    Expression<String>? workspaceId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (keyHash != null) 'key_hash': keyHash,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceRoutesTableCompanion copyWith({
    Value<String>? kind,
    Value<String>? keyHash,
    Value<String>? workspaceId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WorkspaceRoutesTableCompanion(
      kind: kind ?? this.kind,
      keyHash: keyHash ?? this.keyHash,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (keyHash.present) {
      map['key_hash'] = Variable<String>(keyHash.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRoutesTableCompanion(')
          ..write('kind: $kind, ')
          ..write('keyHash: $keyHash, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InviteSecureRoutesTableTable extends InviteSecureRoutesTable
    with TableInfo<$InviteSecureRoutesTableTable, InviteSecureRoutesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InviteSecureRoutesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeHashMeta = const VerificationMeta(
    'codeHash',
  );
  @override
  late final GeneratedColumn<String> codeHash = GeneratedColumn<String>(
    'code_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [routeId, codeHash, workspaceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invite_secure_routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<InviteSecureRoutesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('code_hash')) {
      context.handle(
        _codeHashMeta,
        codeHash.isAcceptableOrUnknown(data['code_hash']!, _codeHashMeta),
      );
    } else if (isInserting) {
      context.missing(_codeHashMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routeId};
  @override
  InviteSecureRoutesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InviteSecureRoutesTableData(
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      )!,
      codeHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_hash'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
    );
  }

  @override
  $InviteSecureRoutesTableTable createAlias(String alias) {
    return $InviteSecureRoutesTableTable(attachedDatabase, alias);
  }
}

class InviteSecureRoutesTableData extends DataClass
    implements Insertable<InviteSecureRoutesTableData> {
  /// The public id a client derives from the invite code.
  final String routeId;

  /// `SHA-256(code)`: the handshake PSK. Never sent to a caller.
  final String codeHash;

  /// The workspace the invite belongs to; the route goes with it.
  final String workspaceId;
  const InviteSecureRoutesTableData({
    required this.routeId,
    required this.codeHash,
    required this.workspaceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['route_id'] = Variable<String>(routeId);
    map['code_hash'] = Variable<String>(codeHash);
    map['workspace_id'] = Variable<String>(workspaceId);
    return map;
  }

  InviteSecureRoutesTableCompanion toCompanion(bool nullToAbsent) {
    return InviteSecureRoutesTableCompanion(
      routeId: Value(routeId),
      codeHash: Value(codeHash),
      workspaceId: Value(workspaceId),
    );
  }

  factory InviteSecureRoutesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InviteSecureRoutesTableData(
      routeId: serializer.fromJson<String>(json['routeId']),
      codeHash: serializer.fromJson<String>(json['codeHash']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routeId': serializer.toJson<String>(routeId),
      'codeHash': serializer.toJson<String>(codeHash),
      'workspaceId': serializer.toJson<String>(workspaceId),
    };
  }

  InviteSecureRoutesTableData copyWith({
    String? routeId,
    String? codeHash,
    String? workspaceId,
  }) => InviteSecureRoutesTableData(
    routeId: routeId ?? this.routeId,
    codeHash: codeHash ?? this.codeHash,
    workspaceId: workspaceId ?? this.workspaceId,
  );
  InviteSecureRoutesTableData copyWithCompanion(
    InviteSecureRoutesTableCompanion data,
  ) {
    return InviteSecureRoutesTableData(
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      codeHash: data.codeHash.present ? data.codeHash.value : this.codeHash,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InviteSecureRoutesTableData(')
          ..write('routeId: $routeId, ')
          ..write('codeHash: $codeHash, ')
          ..write('workspaceId: $workspaceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(routeId, codeHash, workspaceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InviteSecureRoutesTableData &&
          other.routeId == this.routeId &&
          other.codeHash == this.codeHash &&
          other.workspaceId == this.workspaceId);
}

class InviteSecureRoutesTableCompanion
    extends UpdateCompanion<InviteSecureRoutesTableData> {
  final Value<String> routeId;
  final Value<String> codeHash;
  final Value<String> workspaceId;
  final Value<int> rowid;
  const InviteSecureRoutesTableCompanion({
    this.routeId = const Value.absent(),
    this.codeHash = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InviteSecureRoutesTableCompanion.insert({
    required String routeId,
    required String codeHash,
    required String workspaceId,
    this.rowid = const Value.absent(),
  }) : routeId = Value(routeId),
       codeHash = Value(codeHash),
       workspaceId = Value(workspaceId);
  static Insertable<InviteSecureRoutesTableData> custom({
    Expression<String>? routeId,
    Expression<String>? codeHash,
    Expression<String>? workspaceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routeId != null) 'route_id': routeId,
      if (codeHash != null) 'code_hash': codeHash,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InviteSecureRoutesTableCompanion copyWith({
    Value<String>? routeId,
    Value<String>? codeHash,
    Value<String>? workspaceId,
    Value<int>? rowid,
  }) {
    return InviteSecureRoutesTableCompanion(
      routeId: routeId ?? this.routeId,
      codeHash: codeHash ?? this.codeHash,
      workspaceId: workspaceId ?? this.workspaceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (codeHash.present) {
      map['code_hash'] = Variable<String>(codeHash.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InviteSecureRoutesTableCompanion(')
          ..write('routeId: $routeId, ')
          ..write('codeHash: $codeHash, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServerMetaTableTable extends ServerMetaTable
    with TableInfo<$ServerMetaTableTable, ServerMetaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServerMetaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'server_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerMetaTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ServerMetaTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerMetaTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $ServerMetaTableTable createAlias(String alias) {
    return $ServerMetaTableTable(attachedDatabase, alias);
  }
}

class ServerMetaTableData extends DataClass
    implements Insertable<ServerMetaTableData> {
  /// Metadata key.
  final String key;

  /// Metadata value.
  final String value;
  const ServerMetaTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ServerMetaTableCompanion toCompanion(bool nullToAbsent) {
    return ServerMetaTableCompanion(key: Value(key), value: Value(value));
  }

  factory ServerMetaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerMetaTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  ServerMetaTableData copyWith({String? key, String? value}) =>
      ServerMetaTableData(key: key ?? this.key, value: value ?? this.value);
  ServerMetaTableData copyWithCompanion(ServerMetaTableCompanion data) {
    return ServerMetaTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerMetaTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerMetaTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class ServerMetaTableCompanion extends UpdateCompanion<ServerMetaTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ServerMetaTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServerMetaTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<ServerMetaTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServerMetaTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ServerMetaTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServerMetaTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServerSettingsTableTable extends ServerSettingsTable
    with TableInfo<$ServerSettingsTableTable, ServerSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServerSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'server_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ServerSettingsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerSettingsTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ServerSettingsTableTable createAlias(String alias) {
    return $ServerSettingsTableTable(attachedDatabase, alias);
  }
}

class ServerSettingsTableData extends DataClass
    implements Insertable<ServerSettingsTableData> {
  /// Setting key.
  final String key;

  /// Opaque setting value.
  final String value;

  /// When the value was last written.
  final DateTime updatedAt;
  const ServerSettingsTableData({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ServerSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return ServerSettingsTableCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory ServerSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerSettingsTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ServerSettingsTableData copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => ServerSettingsTableData(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ServerSettingsTableData copyWithCompanion(ServerSettingsTableCompanion data) {
    return ServerSettingsTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerSettingsTableData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerSettingsTableData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class ServerSettingsTableCompanion
    extends UpdateCompanion<ServerSettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ServerSettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServerSettingsTableCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<ServerSettingsTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServerSettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ServerSettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServerSettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SsoConnectionsTableTable extends SsoConnectionsTable
    with TableInfo<$SsoConnectionsTableTable, SsoConnectionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SsoConnectionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    check: () => id.isIn(PlatformStoredValues.ssoProviderKind),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(PlatformStoredValues.ssoProviderKind),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _issuerMeta = const VerificationMeta('issuer');
  @override
  late final GeneratedColumn<String> issuer = GeneratedColumn<String>(
    'issuer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _groupsClaimMeta = const VerificationMeta(
    'groupsClaim',
  );
  @override
  late final GeneratedColumn<String> groupsClaim = GeneratedColumn<String>(
    'groups_claim',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('groups'),
  );
  static const VerificationMeta _idpMetadataXmlMeta = const VerificationMeta(
    'idpMetadataXml',
  );
  @override
  late final GeneratedColumn<String> idpMetadataXml = GeneratedColumn<String>(
    'idp_metadata_xml',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _spEntityIdMeta = const VerificationMeta(
    'spEntityId',
  );
  @override
  late final GeneratedColumn<String> spEntityId = GeneratedColumn<String>(
    'sp_entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailAttributeMeta = const VerificationMeta(
    'emailAttribute',
  );
  @override
  late final GeneratedColumn<String> emailAttribute = GeneratedColumn<String>(
    'email_attribute',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('email'),
  );
  static const VerificationMeta _displayNameAttributeMeta =
      const VerificationMeta('displayNameAttribute');
  @override
  late final GeneratedColumn<String> displayNameAttribute =
      GeneratedColumn<String>(
        'display_name_attribute',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('displayName'),
      );
  static const VerificationMeta _groupsAttributeMeta = const VerificationMeta(
    'groupsAttribute',
  );
  @override
  late final GeneratedColumn<String> groupsAttribute = GeneratedColumn<String>(
    'groups_attribute',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('groups'),
  );
  static const VerificationMeta _defaultRoleMeta = const VerificationMeta(
    'defaultRole',
  );
  @override
  late final GeneratedColumn<String> defaultRole = GeneratedColumn<String>(
    'default_role',
    aliasedName,
    false,
    check: () => defaultRole.isIn(PlatformStoredValues.workspaceRole),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('member'),
  );
  static const VerificationMeta _groupRoleMapMeta = const VerificationMeta(
    'groupRoleMap',
  );
  @override
  late final GeneratedColumn<String> groupRoleMap = GeneratedColumn<String>(
    'group_role_map',
    aliasedName,
    false,
    check: () => isJsonObject(groupRoleMap),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _autoMemberMeta = const VerificationMeta(
    'autoMember',
  );
  @override
  late final GeneratedColumn<bool> autoMember = GeneratedColumn<bool>(
    'auto_member',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_member" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _allowJitMeta = const VerificationMeta(
    'allowJit',
  );
  @override
  late final GeneratedColumn<bool> allowJit = GeneratedColumn<bool>(
    'allow_jit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_jit" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _allowIdpInitiatedMeta = const VerificationMeta(
    'allowIdpInitiated',
  );
  @override
  late final GeneratedColumn<bool> allowIdpInitiated = GeneratedColumn<bool>(
    'allow_idp_initiated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_idp_initiated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _wantResponseSignedMeta =
      const VerificationMeta('wantResponseSigned');
  @override
  late final GeneratedColumn<bool> wantResponseSigned = GeneratedColumn<bool>(
    'want_response_signed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("want_response_signed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _clockSkewSecondsMeta = const VerificationMeta(
    'clockSkewSeconds',
  );
  @override
  late final GeneratedColumn<int> clockSkewSeconds = GeneratedColumn<int>(
    'clock_skew_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    enabled,
    issuer,
    clientId,
    groupsClaim,
    idpMetadataXml,
    spEntityId,
    emailAttribute,
    displayNameAttribute,
    groupsAttribute,
    defaultRole,
    groupRoleMap,
    autoMember,
    allowJit,
    allowIdpInitiated,
    wantResponseSigned,
    clockSkewSeconds,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sso_connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<SsoConnectionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('issuer')) {
      context.handle(
        _issuerMeta,
        issuer.isAcceptableOrUnknown(data['issuer']!, _issuerMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('groups_claim')) {
      context.handle(
        _groupsClaimMeta,
        groupsClaim.isAcceptableOrUnknown(
          data['groups_claim']!,
          _groupsClaimMeta,
        ),
      );
    }
    if (data.containsKey('idp_metadata_xml')) {
      context.handle(
        _idpMetadataXmlMeta,
        idpMetadataXml.isAcceptableOrUnknown(
          data['idp_metadata_xml']!,
          _idpMetadataXmlMeta,
        ),
      );
    }
    if (data.containsKey('sp_entity_id')) {
      context.handle(
        _spEntityIdMeta,
        spEntityId.isAcceptableOrUnknown(
          data['sp_entity_id']!,
          _spEntityIdMeta,
        ),
      );
    }
    if (data.containsKey('email_attribute')) {
      context.handle(
        _emailAttributeMeta,
        emailAttribute.isAcceptableOrUnknown(
          data['email_attribute']!,
          _emailAttributeMeta,
        ),
      );
    }
    if (data.containsKey('display_name_attribute')) {
      context.handle(
        _displayNameAttributeMeta,
        displayNameAttribute.isAcceptableOrUnknown(
          data['display_name_attribute']!,
          _displayNameAttributeMeta,
        ),
      );
    }
    if (data.containsKey('groups_attribute')) {
      context.handle(
        _groupsAttributeMeta,
        groupsAttribute.isAcceptableOrUnknown(
          data['groups_attribute']!,
          _groupsAttributeMeta,
        ),
      );
    }
    if (data.containsKey('default_role')) {
      context.handle(
        _defaultRoleMeta,
        defaultRole.isAcceptableOrUnknown(
          data['default_role']!,
          _defaultRoleMeta,
        ),
      );
    }
    if (data.containsKey('group_role_map')) {
      context.handle(
        _groupRoleMapMeta,
        groupRoleMap.isAcceptableOrUnknown(
          data['group_role_map']!,
          _groupRoleMapMeta,
        ),
      );
    }
    if (data.containsKey('auto_member')) {
      context.handle(
        _autoMemberMeta,
        autoMember.isAcceptableOrUnknown(data['auto_member']!, _autoMemberMeta),
      );
    }
    if (data.containsKey('allow_jit')) {
      context.handle(
        _allowJitMeta,
        allowJit.isAcceptableOrUnknown(data['allow_jit']!, _allowJitMeta),
      );
    }
    if (data.containsKey('allow_idp_initiated')) {
      context.handle(
        _allowIdpInitiatedMeta,
        allowIdpInitiated.isAcceptableOrUnknown(
          data['allow_idp_initiated']!,
          _allowIdpInitiatedMeta,
        ),
      );
    }
    if (data.containsKey('want_response_signed')) {
      context.handle(
        _wantResponseSignedMeta,
        wantResponseSigned.isAcceptableOrUnknown(
          data['want_response_signed']!,
          _wantResponseSignedMeta,
        ),
      );
    }
    if (data.containsKey('clock_skew_seconds')) {
      context.handle(
        _clockSkewSecondsMeta,
        clockSkewSeconds.isAcceptableOrUnknown(
          data['clock_skew_seconds']!,
          _clockSkewSecondsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SsoConnectionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SsoConnectionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      issuer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      groupsClaim: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}groups_claim'],
      )!,
      idpMetadataXml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idp_metadata_xml'],
      )!,
      spEntityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sp_entity_id'],
      )!,
      emailAttribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email_attribute'],
      )!,
      displayNameAttribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name_attribute'],
      )!,
      groupsAttribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}groups_attribute'],
      )!,
      defaultRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_role'],
      )!,
      groupRoleMap: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_role_map'],
      )!,
      autoMember: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_member'],
      )!,
      allowJit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_jit'],
      )!,
      allowIdpInitiated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_idp_initiated'],
      )!,
      wantResponseSigned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}want_response_signed'],
      )!,
      clockSkewSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clock_skew_seconds'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SsoConnectionsTableTable createAlias(String alias) {
    return $SsoConnectionsTableTable(attachedDatabase, alias);
  }
}

class SsoConnectionsTableData extends DataClass
    implements Insertable<SsoConnectionsTableData> {
  /// Row id: the kind slug (`saml` / `oidc`).
  final String id;

  /// Protocol kind: an `SsoProviderKind` wire name.
  final String kind;

  /// Whether logins may use this connection.
  final bool enabled;

  /// OIDC issuer base URL.
  final String issuer;

  /// OIDC public-client id.
  final String clientId;

  /// OIDC claim carrying group names.
  final String groupsClaim;

  /// SAML IdP EntityDescriptor XML.
  final String idpMetadataXml;

  /// SAML our entityID; empty derives `<origin>/saml`.
  final String spEntityId;

  /// SAML attribute carrying the email.
  final String emailAttribute;

  /// SAML attribute carrying the display name.
  final String displayNameAttribute;

  /// SAML attribute carrying group names.
  final String groupsAttribute;

  /// Role granted when no group maps: a preset `WorkspaceRole` wire name
  /// (custom roles belong to one workspace; this row serves all of them).
  final String defaultRole;

  /// Group value → role, as a JSON object of wire names.
  final String groupRoleMap;

  /// Whether SSO users are auto-added to workspace memberships (`all`/`none`).
  final bool autoMember;

  /// Whether unknown users may be provisioned at login.
  final bool allowJit;

  /// SAML: accept unsolicited (IdP-initiated) Responses.
  final bool allowIdpInitiated;

  /// SAML: require a Response-root signature too.
  final bool wantResponseSigned;

  /// SAML: validation clock skew, seconds.
  final int clockSkewSeconds;

  /// When this row was last saved.
  final DateTime updatedAt;
  const SsoConnectionsTableData({
    required this.id,
    required this.kind,
    required this.enabled,
    required this.issuer,
    required this.clientId,
    required this.groupsClaim,
    required this.idpMetadataXml,
    required this.spEntityId,
    required this.emailAttribute,
    required this.displayNameAttribute,
    required this.groupsAttribute,
    required this.defaultRole,
    required this.groupRoleMap,
    required this.autoMember,
    required this.allowJit,
    required this.allowIdpInitiated,
    required this.wantResponseSigned,
    required this.clockSkewSeconds,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['enabled'] = Variable<bool>(enabled);
    map['issuer'] = Variable<String>(issuer);
    map['client_id'] = Variable<String>(clientId);
    map['groups_claim'] = Variable<String>(groupsClaim);
    map['idp_metadata_xml'] = Variable<String>(idpMetadataXml);
    map['sp_entity_id'] = Variable<String>(spEntityId);
    map['email_attribute'] = Variable<String>(emailAttribute);
    map['display_name_attribute'] = Variable<String>(displayNameAttribute);
    map['groups_attribute'] = Variable<String>(groupsAttribute);
    map['default_role'] = Variable<String>(defaultRole);
    map['group_role_map'] = Variable<String>(groupRoleMap);
    map['auto_member'] = Variable<bool>(autoMember);
    map['allow_jit'] = Variable<bool>(allowJit);
    map['allow_idp_initiated'] = Variable<bool>(allowIdpInitiated);
    map['want_response_signed'] = Variable<bool>(wantResponseSigned);
    map['clock_skew_seconds'] = Variable<int>(clockSkewSeconds);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SsoConnectionsTableCompanion toCompanion(bool nullToAbsent) {
    return SsoConnectionsTableCompanion(
      id: Value(id),
      kind: Value(kind),
      enabled: Value(enabled),
      issuer: Value(issuer),
      clientId: Value(clientId),
      groupsClaim: Value(groupsClaim),
      idpMetadataXml: Value(idpMetadataXml),
      spEntityId: Value(spEntityId),
      emailAttribute: Value(emailAttribute),
      displayNameAttribute: Value(displayNameAttribute),
      groupsAttribute: Value(groupsAttribute),
      defaultRole: Value(defaultRole),
      groupRoleMap: Value(groupRoleMap),
      autoMember: Value(autoMember),
      allowJit: Value(allowJit),
      allowIdpInitiated: Value(allowIdpInitiated),
      wantResponseSigned: Value(wantResponseSigned),
      clockSkewSeconds: Value(clockSkewSeconds),
      updatedAt: Value(updatedAt),
    );
  }

  factory SsoConnectionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SsoConnectionsTableData(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      issuer: serializer.fromJson<String>(json['issuer']),
      clientId: serializer.fromJson<String>(json['clientId']),
      groupsClaim: serializer.fromJson<String>(json['groupsClaim']),
      idpMetadataXml: serializer.fromJson<String>(json['idpMetadataXml']),
      spEntityId: serializer.fromJson<String>(json['spEntityId']),
      emailAttribute: serializer.fromJson<String>(json['emailAttribute']),
      displayNameAttribute: serializer.fromJson<String>(
        json['displayNameAttribute'],
      ),
      groupsAttribute: serializer.fromJson<String>(json['groupsAttribute']),
      defaultRole: serializer.fromJson<String>(json['defaultRole']),
      groupRoleMap: serializer.fromJson<String>(json['groupRoleMap']),
      autoMember: serializer.fromJson<bool>(json['autoMember']),
      allowJit: serializer.fromJson<bool>(json['allowJit']),
      allowIdpInitiated: serializer.fromJson<bool>(json['allowIdpInitiated']),
      wantResponseSigned: serializer.fromJson<bool>(json['wantResponseSigned']),
      clockSkewSeconds: serializer.fromJson<int>(json['clockSkewSeconds']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'enabled': serializer.toJson<bool>(enabled),
      'issuer': serializer.toJson<String>(issuer),
      'clientId': serializer.toJson<String>(clientId),
      'groupsClaim': serializer.toJson<String>(groupsClaim),
      'idpMetadataXml': serializer.toJson<String>(idpMetadataXml),
      'spEntityId': serializer.toJson<String>(spEntityId),
      'emailAttribute': serializer.toJson<String>(emailAttribute),
      'displayNameAttribute': serializer.toJson<String>(displayNameAttribute),
      'groupsAttribute': serializer.toJson<String>(groupsAttribute),
      'defaultRole': serializer.toJson<String>(defaultRole),
      'groupRoleMap': serializer.toJson<String>(groupRoleMap),
      'autoMember': serializer.toJson<bool>(autoMember),
      'allowJit': serializer.toJson<bool>(allowJit),
      'allowIdpInitiated': serializer.toJson<bool>(allowIdpInitiated),
      'wantResponseSigned': serializer.toJson<bool>(wantResponseSigned),
      'clockSkewSeconds': serializer.toJson<int>(clockSkewSeconds),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SsoConnectionsTableData copyWith({
    String? id,
    String? kind,
    bool? enabled,
    String? issuer,
    String? clientId,
    String? groupsClaim,
    String? idpMetadataXml,
    String? spEntityId,
    String? emailAttribute,
    String? displayNameAttribute,
    String? groupsAttribute,
    String? defaultRole,
    String? groupRoleMap,
    bool? autoMember,
    bool? allowJit,
    bool? allowIdpInitiated,
    bool? wantResponseSigned,
    int? clockSkewSeconds,
    DateTime? updatedAt,
  }) => SsoConnectionsTableData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    enabled: enabled ?? this.enabled,
    issuer: issuer ?? this.issuer,
    clientId: clientId ?? this.clientId,
    groupsClaim: groupsClaim ?? this.groupsClaim,
    idpMetadataXml: idpMetadataXml ?? this.idpMetadataXml,
    spEntityId: spEntityId ?? this.spEntityId,
    emailAttribute: emailAttribute ?? this.emailAttribute,
    displayNameAttribute: displayNameAttribute ?? this.displayNameAttribute,
    groupsAttribute: groupsAttribute ?? this.groupsAttribute,
    defaultRole: defaultRole ?? this.defaultRole,
    groupRoleMap: groupRoleMap ?? this.groupRoleMap,
    autoMember: autoMember ?? this.autoMember,
    allowJit: allowJit ?? this.allowJit,
    allowIdpInitiated: allowIdpInitiated ?? this.allowIdpInitiated,
    wantResponseSigned: wantResponseSigned ?? this.wantResponseSigned,
    clockSkewSeconds: clockSkewSeconds ?? this.clockSkewSeconds,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SsoConnectionsTableData copyWithCompanion(SsoConnectionsTableCompanion data) {
    return SsoConnectionsTableData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      issuer: data.issuer.present ? data.issuer.value : this.issuer,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      groupsClaim: data.groupsClaim.present
          ? data.groupsClaim.value
          : this.groupsClaim,
      idpMetadataXml: data.idpMetadataXml.present
          ? data.idpMetadataXml.value
          : this.idpMetadataXml,
      spEntityId: data.spEntityId.present
          ? data.spEntityId.value
          : this.spEntityId,
      emailAttribute: data.emailAttribute.present
          ? data.emailAttribute.value
          : this.emailAttribute,
      displayNameAttribute: data.displayNameAttribute.present
          ? data.displayNameAttribute.value
          : this.displayNameAttribute,
      groupsAttribute: data.groupsAttribute.present
          ? data.groupsAttribute.value
          : this.groupsAttribute,
      defaultRole: data.defaultRole.present
          ? data.defaultRole.value
          : this.defaultRole,
      groupRoleMap: data.groupRoleMap.present
          ? data.groupRoleMap.value
          : this.groupRoleMap,
      autoMember: data.autoMember.present
          ? data.autoMember.value
          : this.autoMember,
      allowJit: data.allowJit.present ? data.allowJit.value : this.allowJit,
      allowIdpInitiated: data.allowIdpInitiated.present
          ? data.allowIdpInitiated.value
          : this.allowIdpInitiated,
      wantResponseSigned: data.wantResponseSigned.present
          ? data.wantResponseSigned.value
          : this.wantResponseSigned,
      clockSkewSeconds: data.clockSkewSeconds.present
          ? data.clockSkewSeconds.value
          : this.clockSkewSeconds,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SsoConnectionsTableData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('enabled: $enabled, ')
          ..write('issuer: $issuer, ')
          ..write('clientId: $clientId, ')
          ..write('groupsClaim: $groupsClaim, ')
          ..write('idpMetadataXml: $idpMetadataXml, ')
          ..write('spEntityId: $spEntityId, ')
          ..write('emailAttribute: $emailAttribute, ')
          ..write('displayNameAttribute: $displayNameAttribute, ')
          ..write('groupsAttribute: $groupsAttribute, ')
          ..write('defaultRole: $defaultRole, ')
          ..write('groupRoleMap: $groupRoleMap, ')
          ..write('autoMember: $autoMember, ')
          ..write('allowJit: $allowJit, ')
          ..write('allowIdpInitiated: $allowIdpInitiated, ')
          ..write('wantResponseSigned: $wantResponseSigned, ')
          ..write('clockSkewSeconds: $clockSkewSeconds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    enabled,
    issuer,
    clientId,
    groupsClaim,
    idpMetadataXml,
    spEntityId,
    emailAttribute,
    displayNameAttribute,
    groupsAttribute,
    defaultRole,
    groupRoleMap,
    autoMember,
    allowJit,
    allowIdpInitiated,
    wantResponseSigned,
    clockSkewSeconds,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SsoConnectionsTableData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.enabled == this.enabled &&
          other.issuer == this.issuer &&
          other.clientId == this.clientId &&
          other.groupsClaim == this.groupsClaim &&
          other.idpMetadataXml == this.idpMetadataXml &&
          other.spEntityId == this.spEntityId &&
          other.emailAttribute == this.emailAttribute &&
          other.displayNameAttribute == this.displayNameAttribute &&
          other.groupsAttribute == this.groupsAttribute &&
          other.defaultRole == this.defaultRole &&
          other.groupRoleMap == this.groupRoleMap &&
          other.autoMember == this.autoMember &&
          other.allowJit == this.allowJit &&
          other.allowIdpInitiated == this.allowIdpInitiated &&
          other.wantResponseSigned == this.wantResponseSigned &&
          other.clockSkewSeconds == this.clockSkewSeconds &&
          other.updatedAt == this.updatedAt);
}

class SsoConnectionsTableCompanion
    extends UpdateCompanion<SsoConnectionsTableData> {
  final Value<String> id;
  final Value<String> kind;
  final Value<bool> enabled;
  final Value<String> issuer;
  final Value<String> clientId;
  final Value<String> groupsClaim;
  final Value<String> idpMetadataXml;
  final Value<String> spEntityId;
  final Value<String> emailAttribute;
  final Value<String> displayNameAttribute;
  final Value<String> groupsAttribute;
  final Value<String> defaultRole;
  final Value<String> groupRoleMap;
  final Value<bool> autoMember;
  final Value<bool> allowJit;
  final Value<bool> allowIdpInitiated;
  final Value<bool> wantResponseSigned;
  final Value<int> clockSkewSeconds;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SsoConnectionsTableCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.enabled = const Value.absent(),
    this.issuer = const Value.absent(),
    this.clientId = const Value.absent(),
    this.groupsClaim = const Value.absent(),
    this.idpMetadataXml = const Value.absent(),
    this.spEntityId = const Value.absent(),
    this.emailAttribute = const Value.absent(),
    this.displayNameAttribute = const Value.absent(),
    this.groupsAttribute = const Value.absent(),
    this.defaultRole = const Value.absent(),
    this.groupRoleMap = const Value.absent(),
    this.autoMember = const Value.absent(),
    this.allowJit = const Value.absent(),
    this.allowIdpInitiated = const Value.absent(),
    this.wantResponseSigned = const Value.absent(),
    this.clockSkewSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SsoConnectionsTableCompanion.insert({
    required String id,
    required String kind,
    this.enabled = const Value.absent(),
    this.issuer = const Value.absent(),
    this.clientId = const Value.absent(),
    this.groupsClaim = const Value.absent(),
    this.idpMetadataXml = const Value.absent(),
    this.spEntityId = const Value.absent(),
    this.emailAttribute = const Value.absent(),
    this.displayNameAttribute = const Value.absent(),
    this.groupsAttribute = const Value.absent(),
    this.defaultRole = const Value.absent(),
    this.groupRoleMap = const Value.absent(),
    this.autoMember = const Value.absent(),
    this.allowJit = const Value.absent(),
    this.allowIdpInitiated = const Value.absent(),
    this.wantResponseSigned = const Value.absent(),
    this.clockSkewSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind);
  static Insertable<SsoConnectionsTableData> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<bool>? enabled,
    Expression<String>? issuer,
    Expression<String>? clientId,
    Expression<String>? groupsClaim,
    Expression<String>? idpMetadataXml,
    Expression<String>? spEntityId,
    Expression<String>? emailAttribute,
    Expression<String>? displayNameAttribute,
    Expression<String>? groupsAttribute,
    Expression<String>? defaultRole,
    Expression<String>? groupRoleMap,
    Expression<bool>? autoMember,
    Expression<bool>? allowJit,
    Expression<bool>? allowIdpInitiated,
    Expression<bool>? wantResponseSigned,
    Expression<int>? clockSkewSeconds,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (enabled != null) 'enabled': enabled,
      if (issuer != null) 'issuer': issuer,
      if (clientId != null) 'client_id': clientId,
      if (groupsClaim != null) 'groups_claim': groupsClaim,
      if (idpMetadataXml != null) 'idp_metadata_xml': idpMetadataXml,
      if (spEntityId != null) 'sp_entity_id': spEntityId,
      if (emailAttribute != null) 'email_attribute': emailAttribute,
      if (displayNameAttribute != null)
        'display_name_attribute': displayNameAttribute,
      if (groupsAttribute != null) 'groups_attribute': groupsAttribute,
      if (defaultRole != null) 'default_role': defaultRole,
      if (groupRoleMap != null) 'group_role_map': groupRoleMap,
      if (autoMember != null) 'auto_member': autoMember,
      if (allowJit != null) 'allow_jit': allowJit,
      if (allowIdpInitiated != null) 'allow_idp_initiated': allowIdpInitiated,
      if (wantResponseSigned != null)
        'want_response_signed': wantResponseSigned,
      if (clockSkewSeconds != null) 'clock_skew_seconds': clockSkewSeconds,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SsoConnectionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<bool>? enabled,
    Value<String>? issuer,
    Value<String>? clientId,
    Value<String>? groupsClaim,
    Value<String>? idpMetadataXml,
    Value<String>? spEntityId,
    Value<String>? emailAttribute,
    Value<String>? displayNameAttribute,
    Value<String>? groupsAttribute,
    Value<String>? defaultRole,
    Value<String>? groupRoleMap,
    Value<bool>? autoMember,
    Value<bool>? allowJit,
    Value<bool>? allowIdpInitiated,
    Value<bool>? wantResponseSigned,
    Value<int>? clockSkewSeconds,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SsoConnectionsTableCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      enabled: enabled ?? this.enabled,
      issuer: issuer ?? this.issuer,
      clientId: clientId ?? this.clientId,
      groupsClaim: groupsClaim ?? this.groupsClaim,
      idpMetadataXml: idpMetadataXml ?? this.idpMetadataXml,
      spEntityId: spEntityId ?? this.spEntityId,
      emailAttribute: emailAttribute ?? this.emailAttribute,
      displayNameAttribute: displayNameAttribute ?? this.displayNameAttribute,
      groupsAttribute: groupsAttribute ?? this.groupsAttribute,
      defaultRole: defaultRole ?? this.defaultRole,
      groupRoleMap: groupRoleMap ?? this.groupRoleMap,
      autoMember: autoMember ?? this.autoMember,
      allowJit: allowJit ?? this.allowJit,
      allowIdpInitiated: allowIdpInitiated ?? this.allowIdpInitiated,
      wantResponseSigned: wantResponseSigned ?? this.wantResponseSigned,
      clockSkewSeconds: clockSkewSeconds ?? this.clockSkewSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (issuer.present) {
      map['issuer'] = Variable<String>(issuer.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (groupsClaim.present) {
      map['groups_claim'] = Variable<String>(groupsClaim.value);
    }
    if (idpMetadataXml.present) {
      map['idp_metadata_xml'] = Variable<String>(idpMetadataXml.value);
    }
    if (spEntityId.present) {
      map['sp_entity_id'] = Variable<String>(spEntityId.value);
    }
    if (emailAttribute.present) {
      map['email_attribute'] = Variable<String>(emailAttribute.value);
    }
    if (displayNameAttribute.present) {
      map['display_name_attribute'] = Variable<String>(
        displayNameAttribute.value,
      );
    }
    if (groupsAttribute.present) {
      map['groups_attribute'] = Variable<String>(groupsAttribute.value);
    }
    if (defaultRole.present) {
      map['default_role'] = Variable<String>(defaultRole.value);
    }
    if (groupRoleMap.present) {
      map['group_role_map'] = Variable<String>(groupRoleMap.value);
    }
    if (autoMember.present) {
      map['auto_member'] = Variable<bool>(autoMember.value);
    }
    if (allowJit.present) {
      map['allow_jit'] = Variable<bool>(allowJit.value);
    }
    if (allowIdpInitiated.present) {
      map['allow_idp_initiated'] = Variable<bool>(allowIdpInitiated.value);
    }
    if (wantResponseSigned.present) {
      map['want_response_signed'] = Variable<bool>(wantResponseSigned.value);
    }
    if (clockSkewSeconds.present) {
      map['clock_skew_seconds'] = Variable<int>(clockSkewSeconds.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SsoConnectionsTableCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('enabled: $enabled, ')
          ..write('issuer: $issuer, ')
          ..write('clientId: $clientId, ')
          ..write('groupsClaim: $groupsClaim, ')
          ..write('idpMetadataXml: $idpMetadataXml, ')
          ..write('spEntityId: $spEntityId, ')
          ..write('emailAttribute: $emailAttribute, ')
          ..write('displayNameAttribute: $displayNameAttribute, ')
          ..write('groupsAttribute: $groupsAttribute, ')
          ..write('defaultRole: $defaultRole, ')
          ..write('groupRoleMap: $groupRoleMap, ')
          ..write('autoMember: $autoMember, ')
          ..write('allowJit: $allowJit, ')
          ..write('allowIdpInitiated: $allowIdpInitiated, ')
          ..write('wantResponseSigned: $wantResponseSigned, ')
          ..write('clockSkewSeconds: $clockSkewSeconds, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ManagedActionPoliciesTableTable extends ManagedActionPoliciesTable
    with
        TableInfo<
          $ManagedActionPoliciesTableTable,
          ManagedActionPoliciesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManagedActionPoliciesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionClassMeta = const VerificationMeta(
    'actionClass',
  );
  @override
  late final GeneratedColumn<String> actionClass = GeneratedColumn<String>(
    'action_class',
    aliasedName,
    true,
    check: () => actionClass.isIn(PlatformStoredValues.actionClass),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commandPrefixMeta = const VerificationMeta(
    'commandPrefix',
  );
  @override
  late final GeneratedColumn<String> commandPrefix = GeneratedColumn<String>(
    'command_prefix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decisionMeta = const VerificationMeta(
    'decision',
  );
  @override
  late final GeneratedColumn<String> decision = GeneratedColumn<String>(
    'decision',
    aliasedName,
    false,
    check: () => decision.isIn(PlatformStoredValues.actionDecision),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('prompt'),
  );
  static const VerificationMeta _enforcementMeta = const VerificationMeta(
    'enforcement',
  );
  @override
  late final GeneratedColumn<String> enforcement = GeneratedColumn<String>(
    'enforcement',
    aliasedName,
    true,
    check: () => enforcement.isIn(PlatformStoredValues.enforcementLevel),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _constraintJsonMeta = const VerificationMeta(
    'constraintJson',
  );
  @override
  late final GeneratedColumn<String> constraintJson = GeneratedColumn<String>(
    'constraint_json',
    aliasedName,
    true,
    check: () => isJsonObject(constraintJson),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actionClass,
    commandPrefix,
    decision,
    enforcement,
    constraintJson,
    updatedBy,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'managed_action_policies';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManagedActionPoliciesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('action_class')) {
      context.handle(
        _actionClassMeta,
        actionClass.isAcceptableOrUnknown(
          data['action_class']!,
          _actionClassMeta,
        ),
      );
    }
    if (data.containsKey('command_prefix')) {
      context.handle(
        _commandPrefixMeta,
        commandPrefix.isAcceptableOrUnknown(
          data['command_prefix']!,
          _commandPrefixMeta,
        ),
      );
    }
    if (data.containsKey('decision')) {
      context.handle(
        _decisionMeta,
        decision.isAcceptableOrUnknown(data['decision']!, _decisionMeta),
      );
    }
    if (data.containsKey('enforcement')) {
      context.handle(
        _enforcementMeta,
        enforcement.isAcceptableOrUnknown(
          data['enforcement']!,
          _enforcementMeta,
        ),
      );
    }
    if (data.containsKey('constraint_json')) {
      context.handle(
        _constraintJsonMeta,
        constraintJson.isAcceptableOrUnknown(
          data['constraint_json']!,
          _constraintJsonMeta,
        ),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ManagedActionPoliciesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManagedActionPoliciesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actionClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_class'],
      ),
      commandPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command_prefix'],
      ),
      decision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decision'],
      )!,
      enforcement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enforcement'],
      ),
      constraintJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}constraint_json'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ManagedActionPoliciesTableTable createAlias(String alias) {
    return $ManagedActionPoliciesTableTable(attachedDatabase, alias);
  }
}

class ManagedActionPoliciesTableData extends DataClass
    implements Insertable<ManagedActionPoliciesTableData> {
  /// Unique row id (UUID v4).
  final String id;

  /// The ActionClass wire name this rule governs (null when a
  /// [commandPrefix] rule instead). Exactly one of the two is set.
  final String? actionClass;

  /// A command prefix this rule governs (null when an [actionClass] rule).
  final String? commandPrefix;

  /// The decision: `allow` / `prompt` / `deny`. (`allow` is stored but can
  /// only ever confirm — the merge is most-restrictive.) An `ActionDecision`
  /// wire name.
  final String decision;

  /// Enforcement level: an `EnforcementLevel` wire name (null = `hard`).
  final String? enforcement;

  /// Optional argument constraint (`ActionConstraint` wire shape): a JSON
  /// object.
  final String? constraintJson;

  /// The user who last wrote the rule (the server owner). History: cleared
  /// if the user row goes.
  final String? updatedBy;

  /// Last mutation time.
  final DateTime updatedAt;
  const ManagedActionPoliciesTableData({
    required this.id,
    this.actionClass,
    this.commandPrefix,
    required this.decision,
    this.enforcement,
    this.constraintJson,
    this.updatedBy,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || actionClass != null) {
      map['action_class'] = Variable<String>(actionClass);
    }
    if (!nullToAbsent || commandPrefix != null) {
      map['command_prefix'] = Variable<String>(commandPrefix);
    }
    map['decision'] = Variable<String>(decision);
    if (!nullToAbsent || enforcement != null) {
      map['enforcement'] = Variable<String>(enforcement);
    }
    if (!nullToAbsent || constraintJson != null) {
      map['constraint_json'] = Variable<String>(constraintJson);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ManagedActionPoliciesTableCompanion toCompanion(bool nullToAbsent) {
    return ManagedActionPoliciesTableCompanion(
      id: Value(id),
      actionClass: actionClass == null && nullToAbsent
          ? const Value.absent()
          : Value(actionClass),
      commandPrefix: commandPrefix == null && nullToAbsent
          ? const Value.absent()
          : Value(commandPrefix),
      decision: Value(decision),
      enforcement: enforcement == null && nullToAbsent
          ? const Value.absent()
          : Value(enforcement),
      constraintJson: constraintJson == null && nullToAbsent
          ? const Value.absent()
          : Value(constraintJson),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      updatedAt: Value(updatedAt),
    );
  }

  factory ManagedActionPoliciesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManagedActionPoliciesTableData(
      id: serializer.fromJson<String>(json['id']),
      actionClass: serializer.fromJson<String?>(json['actionClass']),
      commandPrefix: serializer.fromJson<String?>(json['commandPrefix']),
      decision: serializer.fromJson<String>(json['decision']),
      enforcement: serializer.fromJson<String?>(json['enforcement']),
      constraintJson: serializer.fromJson<String?>(json['constraintJson']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actionClass': serializer.toJson<String?>(actionClass),
      'commandPrefix': serializer.toJson<String?>(commandPrefix),
      'decision': serializer.toJson<String>(decision),
      'enforcement': serializer.toJson<String?>(enforcement),
      'constraintJson': serializer.toJson<String?>(constraintJson),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ManagedActionPoliciesTableData copyWith({
    String? id,
    Value<String?> actionClass = const Value.absent(),
    Value<String?> commandPrefix = const Value.absent(),
    String? decision,
    Value<String?> enforcement = const Value.absent(),
    Value<String?> constraintJson = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    DateTime? updatedAt,
  }) => ManagedActionPoliciesTableData(
    id: id ?? this.id,
    actionClass: actionClass.present ? actionClass.value : this.actionClass,
    commandPrefix: commandPrefix.present
        ? commandPrefix.value
        : this.commandPrefix,
    decision: decision ?? this.decision,
    enforcement: enforcement.present ? enforcement.value : this.enforcement,
    constraintJson: constraintJson.present
        ? constraintJson.value
        : this.constraintJson,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ManagedActionPoliciesTableData copyWithCompanion(
    ManagedActionPoliciesTableCompanion data,
  ) {
    return ManagedActionPoliciesTableData(
      id: data.id.present ? data.id.value : this.id,
      actionClass: data.actionClass.present
          ? data.actionClass.value
          : this.actionClass,
      commandPrefix: data.commandPrefix.present
          ? data.commandPrefix.value
          : this.commandPrefix,
      decision: data.decision.present ? data.decision.value : this.decision,
      enforcement: data.enforcement.present
          ? data.enforcement.value
          : this.enforcement,
      constraintJson: data.constraintJson.present
          ? data.constraintJson.value
          : this.constraintJson,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManagedActionPoliciesTableData(')
          ..write('id: $id, ')
          ..write('actionClass: $actionClass, ')
          ..write('commandPrefix: $commandPrefix, ')
          ..write('decision: $decision, ')
          ..write('enforcement: $enforcement, ')
          ..write('constraintJson: $constraintJson, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actionClass,
    commandPrefix,
    decision,
    enforcement,
    constraintJson,
    updatedBy,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManagedActionPoliciesTableData &&
          other.id == this.id &&
          other.actionClass == this.actionClass &&
          other.commandPrefix == this.commandPrefix &&
          other.decision == this.decision &&
          other.enforcement == this.enforcement &&
          other.constraintJson == this.constraintJson &&
          other.updatedBy == this.updatedBy &&
          other.updatedAt == this.updatedAt);
}

class ManagedActionPoliciesTableCompanion
    extends UpdateCompanion<ManagedActionPoliciesTableData> {
  final Value<String> id;
  final Value<String?> actionClass;
  final Value<String?> commandPrefix;
  final Value<String> decision;
  final Value<String?> enforcement;
  final Value<String?> constraintJson;
  final Value<String?> updatedBy;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ManagedActionPoliciesTableCompanion({
    this.id = const Value.absent(),
    this.actionClass = const Value.absent(),
    this.commandPrefix = const Value.absent(),
    this.decision = const Value.absent(),
    this.enforcement = const Value.absent(),
    this.constraintJson = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManagedActionPoliciesTableCompanion.insert({
    required String id,
    this.actionClass = const Value.absent(),
    this.commandPrefix = const Value.absent(),
    this.decision = const Value.absent(),
    this.enforcement = const Value.absent(),
    this.constraintJson = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ManagedActionPoliciesTableData> custom({
    Expression<String>? id,
    Expression<String>? actionClass,
    Expression<String>? commandPrefix,
    Expression<String>? decision,
    Expression<String>? enforcement,
    Expression<String>? constraintJson,
    Expression<String>? updatedBy,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionClass != null) 'action_class': actionClass,
      if (commandPrefix != null) 'command_prefix': commandPrefix,
      if (decision != null) 'decision': decision,
      if (enforcement != null) 'enforcement': enforcement,
      if (constraintJson != null) 'constraint_json': constraintJson,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManagedActionPoliciesTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? actionClass,
    Value<String?>? commandPrefix,
    Value<String>? decision,
    Value<String?>? enforcement,
    Value<String?>? constraintJson,
    Value<String?>? updatedBy,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ManagedActionPoliciesTableCompanion(
      id: id ?? this.id,
      actionClass: actionClass ?? this.actionClass,
      commandPrefix: commandPrefix ?? this.commandPrefix,
      decision: decision ?? this.decision,
      enforcement: enforcement ?? this.enforcement,
      constraintJson: constraintJson ?? this.constraintJson,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (actionClass.present) {
      map['action_class'] = Variable<String>(actionClass.value);
    }
    if (commandPrefix.present) {
      map['command_prefix'] = Variable<String>(commandPrefix.value);
    }
    if (decision.present) {
      map['decision'] = Variable<String>(decision.value);
    }
    if (enforcement.present) {
      map['enforcement'] = Variable<String>(enforcement.value);
    }
    if (constraintJson.present) {
      map['constraint_json'] = Variable<String>(constraintJson.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManagedActionPoliciesTableCompanion(')
          ..write('id: $id, ')
          ..write('actionClass: $actionClass, ')
          ..write('commandPrefix: $commandPrefix, ')
          ..write('decision: $decision, ')
          ..write('enforcement: $enforcement, ')
          ..write('constraintJson: $constraintJson, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentSlotLeasesTableTable extends EnvironmentSlotLeasesTable
    with
        TableInfo<
          $EnvironmentSlotLeasesTableTable,
          EnvironmentSlotLeasesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentSlotLeasesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _blockMeta = const VerificationMeta('block');
  @override
  late final GeneratedColumn<int> block = GeneratedColumn<int>(
    'block',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstPortMeta = const VerificationMeta(
    'firstPort',
  );
  @override
  late final GeneratedColumn<int> firstPort = GeneratedColumn<int>(
    'first_port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _spaceIdMeta = const VerificationMeta(
    'spaceId',
  );
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
    'space_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionIdMeta = const VerificationMeta(
    'definitionId',
  );
  @override
  late final GeneratedColumn<String> definitionId = GeneratedColumn<String>(
    'definition_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _poolKeyMeta = const VerificationMeta(
    'poolKey',
  );
  @override
  late final GeneratedColumn<String> poolKey = GeneratedColumn<String>(
    'pool_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _poolSlotMeta = const VerificationMeta(
    'poolSlot',
  );
  @override
  late final GeneratedColumn<int> poolSlot = GeneratedColumn<int>(
    'pool_slot',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    block,
    firstPort,
    size,
    workspaceId,
    spaceId,
    definitionId,
    poolKey,
    poolSlot,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_slot_leases';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentSlotLeasesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('block')) {
      context.handle(
        _blockMeta,
        block.isAcceptableOrUnknown(data['block']!, _blockMeta),
      );
    }
    if (data.containsKey('first_port')) {
      context.handle(
        _firstPortMeta,
        firstPort.isAcceptableOrUnknown(data['first_port']!, _firstPortMeta),
      );
    } else if (isInserting) {
      context.missing(_firstPortMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('space_id')) {
      context.handle(
        _spaceIdMeta,
        spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_spaceIdMeta);
    }
    if (data.containsKey('definition_id')) {
      context.handle(
        _definitionIdMeta,
        definitionId.isAcceptableOrUnknown(
          data['definition_id']!,
          _definitionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionIdMeta);
    }
    if (data.containsKey('pool_key')) {
      context.handle(
        _poolKeyMeta,
        poolKey.isAcceptableOrUnknown(data['pool_key']!, _poolKeyMeta),
      );
    }
    if (data.containsKey('pool_slot')) {
      context.handle(
        _poolSlotMeta,
        poolSlot.isAcceptableOrUnknown(data['pool_slot']!, _poolSlotMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {block};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {poolKey, poolSlot},
    {workspaceId, spaceId, definitionId},
  ];
  @override
  EnvironmentSlotLeasesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentSlotLeasesTableData(
      block: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block'],
      )!,
      firstPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_port'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      spaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}space_id'],
      )!,
      definitionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_id'],
      )!,
      poolKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pool_key'],
      ),
      poolSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pool_slot'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EnvironmentSlotLeasesTableTable createAlias(String alias) {
    return $EnvironmentSlotLeasesTableTable(attachedDatabase, alias);
  }
}

class EnvironmentSlotLeasesTableData extends DataClass
    implements Insertable<EnvironmentSlotLeasesTableData> {
  /// Block index in the configured range.
  final int block;

  /// First port.
  final int firstPort;

  /// Ports in the block.
  final int size;

  /// Holding workspace; the block goes back to the pool with it.
  final String workspaceId;

  /// Holding space. No foreign key: spaces live in the workspace's own
  /// database.
  final String spaceId;

  /// The definition. No foreign key: definitions live in the workspace's own
  /// database.
  final String definitionId;

  /// A name pool, when the environment uses one.
  final String? poolKey;

  /// The pool slot.
  final int? poolSlot;

  /// When it was taken.
  final DateTime createdAt;
  const EnvironmentSlotLeasesTableData({
    required this.block,
    required this.firstPort,
    required this.size,
    required this.workspaceId,
    required this.spaceId,
    required this.definitionId,
    this.poolKey,
    this.poolSlot,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['block'] = Variable<int>(block);
    map['first_port'] = Variable<int>(firstPort);
    map['size'] = Variable<int>(size);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['space_id'] = Variable<String>(spaceId);
    map['definition_id'] = Variable<String>(definitionId);
    if (!nullToAbsent || poolKey != null) {
      map['pool_key'] = Variable<String>(poolKey);
    }
    if (!nullToAbsent || poolSlot != null) {
      map['pool_slot'] = Variable<int>(poolSlot);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EnvironmentSlotLeasesTableCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentSlotLeasesTableCompanion(
      block: Value(block),
      firstPort: Value(firstPort),
      size: Value(size),
      workspaceId: Value(workspaceId),
      spaceId: Value(spaceId),
      definitionId: Value(definitionId),
      poolKey: poolKey == null && nullToAbsent
          ? const Value.absent()
          : Value(poolKey),
      poolSlot: poolSlot == null && nullToAbsent
          ? const Value.absent()
          : Value(poolSlot),
      createdAt: Value(createdAt),
    );
  }

  factory EnvironmentSlotLeasesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentSlotLeasesTableData(
      block: serializer.fromJson<int>(json['block']),
      firstPort: serializer.fromJson<int>(json['firstPort']),
      size: serializer.fromJson<int>(json['size']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      spaceId: serializer.fromJson<String>(json['spaceId']),
      definitionId: serializer.fromJson<String>(json['definitionId']),
      poolKey: serializer.fromJson<String?>(json['poolKey']),
      poolSlot: serializer.fromJson<int?>(json['poolSlot']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'block': serializer.toJson<int>(block),
      'firstPort': serializer.toJson<int>(firstPort),
      'size': serializer.toJson<int>(size),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'spaceId': serializer.toJson<String>(spaceId),
      'definitionId': serializer.toJson<String>(definitionId),
      'poolKey': serializer.toJson<String?>(poolKey),
      'poolSlot': serializer.toJson<int?>(poolSlot),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EnvironmentSlotLeasesTableData copyWith({
    int? block,
    int? firstPort,
    int? size,
    String? workspaceId,
    String? spaceId,
    String? definitionId,
    Value<String?> poolKey = const Value.absent(),
    Value<int?> poolSlot = const Value.absent(),
    DateTime? createdAt,
  }) => EnvironmentSlotLeasesTableData(
    block: block ?? this.block,
    firstPort: firstPort ?? this.firstPort,
    size: size ?? this.size,
    workspaceId: workspaceId ?? this.workspaceId,
    spaceId: spaceId ?? this.spaceId,
    definitionId: definitionId ?? this.definitionId,
    poolKey: poolKey.present ? poolKey.value : this.poolKey,
    poolSlot: poolSlot.present ? poolSlot.value : this.poolSlot,
    createdAt: createdAt ?? this.createdAt,
  );
  EnvironmentSlotLeasesTableData copyWithCompanion(
    EnvironmentSlotLeasesTableCompanion data,
  ) {
    return EnvironmentSlotLeasesTableData(
      block: data.block.present ? data.block.value : this.block,
      firstPort: data.firstPort.present ? data.firstPort.value : this.firstPort,
      size: data.size.present ? data.size.value : this.size,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
      definitionId: data.definitionId.present
          ? data.definitionId.value
          : this.definitionId,
      poolKey: data.poolKey.present ? data.poolKey.value : this.poolKey,
      poolSlot: data.poolSlot.present ? data.poolSlot.value : this.poolSlot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentSlotLeasesTableData(')
          ..write('block: $block, ')
          ..write('firstPort: $firstPort, ')
          ..write('size: $size, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('spaceId: $spaceId, ')
          ..write('definitionId: $definitionId, ')
          ..write('poolKey: $poolKey, ')
          ..write('poolSlot: $poolSlot, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    block,
    firstPort,
    size,
    workspaceId,
    spaceId,
    definitionId,
    poolKey,
    poolSlot,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentSlotLeasesTableData &&
          other.block == this.block &&
          other.firstPort == this.firstPort &&
          other.size == this.size &&
          other.workspaceId == this.workspaceId &&
          other.spaceId == this.spaceId &&
          other.definitionId == this.definitionId &&
          other.poolKey == this.poolKey &&
          other.poolSlot == this.poolSlot &&
          other.createdAt == this.createdAt);
}

class EnvironmentSlotLeasesTableCompanion
    extends UpdateCompanion<EnvironmentSlotLeasesTableData> {
  final Value<int> block;
  final Value<int> firstPort;
  final Value<int> size;
  final Value<String> workspaceId;
  final Value<String> spaceId;
  final Value<String> definitionId;
  final Value<String?> poolKey;
  final Value<int?> poolSlot;
  final Value<DateTime> createdAt;
  const EnvironmentSlotLeasesTableCompanion({
    this.block = const Value.absent(),
    this.firstPort = const Value.absent(),
    this.size = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.definitionId = const Value.absent(),
    this.poolKey = const Value.absent(),
    this.poolSlot = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EnvironmentSlotLeasesTableCompanion.insert({
    this.block = const Value.absent(),
    required int firstPort,
    required int size,
    required String workspaceId,
    required String spaceId,
    required String definitionId,
    this.poolKey = const Value.absent(),
    this.poolSlot = const Value.absent(),
    required DateTime createdAt,
  }) : firstPort = Value(firstPort),
       size = Value(size),
       workspaceId = Value(workspaceId),
       spaceId = Value(spaceId),
       definitionId = Value(definitionId),
       createdAt = Value(createdAt);
  static Insertable<EnvironmentSlotLeasesTableData> custom({
    Expression<int>? block,
    Expression<int>? firstPort,
    Expression<int>? size,
    Expression<String>? workspaceId,
    Expression<String>? spaceId,
    Expression<String>? definitionId,
    Expression<String>? poolKey,
    Expression<int>? poolSlot,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (block != null) 'block': block,
      if (firstPort != null) 'first_port': firstPort,
      if (size != null) 'size': size,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (spaceId != null) 'space_id': spaceId,
      if (definitionId != null) 'definition_id': definitionId,
      if (poolKey != null) 'pool_key': poolKey,
      if (poolSlot != null) 'pool_slot': poolSlot,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EnvironmentSlotLeasesTableCompanion copyWith({
    Value<int>? block,
    Value<int>? firstPort,
    Value<int>? size,
    Value<String>? workspaceId,
    Value<String>? spaceId,
    Value<String>? definitionId,
    Value<String?>? poolKey,
    Value<int?>? poolSlot,
    Value<DateTime>? createdAt,
  }) {
    return EnvironmentSlotLeasesTableCompanion(
      block: block ?? this.block,
      firstPort: firstPort ?? this.firstPort,
      size: size ?? this.size,
      workspaceId: workspaceId ?? this.workspaceId,
      spaceId: spaceId ?? this.spaceId,
      definitionId: definitionId ?? this.definitionId,
      poolKey: poolKey ?? this.poolKey,
      poolSlot: poolSlot ?? this.poolSlot,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (block.present) {
      map['block'] = Variable<int>(block.value);
    }
    if (firstPort.present) {
      map['first_port'] = Variable<int>(firstPort.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (definitionId.present) {
      map['definition_id'] = Variable<String>(definitionId.value);
    }
    if (poolKey.present) {
      map['pool_key'] = Variable<String>(poolKey.value);
    }
    if (poolSlot.present) {
      map['pool_slot'] = Variable<int>(poolSlot.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentSlotLeasesTableCompanion(')
          ..write('block: $block, ')
          ..write('firstPort: $firstPort, ')
          ..write('size: $size, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('spaceId: $spaceId, ')
          ..write('definitionId: $definitionId, ')
          ..write('poolKey: $poolKey, ')
          ..write('poolSlot: $poolSlot, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ServerAuditTableTable extends ServerAuditTable
    with TableInfo<$ServerAuditTableTable, ServerAuditTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServerAuditTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ipMeta = const VerificationMeta('ip');
  @override
  late final GeneratedColumn<String> ip = GeneratedColumn<String>(
    'ip',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _argNamesMeta = const VerificationMeta(
    'argNames',
  );
  @override
  late final GeneratedColumn<String> argNames = GeneratedColumn<String>(
    'arg_names',
    aliasedName,
    false,
    check: () => isJsonArray(argNames),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    check: () => outcome.isIn(PlatformStoredValues.auditOutcome),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    deviceId,
    ip,
    op,
    argNames,
    outcome,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'server_audit';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerAuditTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('ip')) {
      context.handle(_ipMeta, ip.isAcceptableOrUnknown(data['ip']!, _ipMeta));
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('arg_names')) {
      context.handle(
        _argNamesMeta,
        argNames.isAcceptableOrUnknown(data['arg_names']!, _argNamesMeta),
      );
    } else if (isInserting) {
      context.missing(_argNamesMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServerAuditTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerAuditTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      ip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip'],
      ),
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      argNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arg_names'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ServerAuditTableTable createAlias(String alias) {
    return $ServerAuditTableTable(attachedDatabase, alias);
  }
}

class ServerAuditTableData extends DataClass
    implements Insertable<ServerAuditTableData> {
  /// Unique entry identifier.
  final String id;

  /// The person who made the call. No foreign key: the row is written after
  /// the call, which may itself have removed the person's row, and the trail
  /// must keep it either way.
  final String userId;

  /// The device the call came from, when known. No foreign key, for the same
  /// reason (revoking a device is an audited call).
  final String? deviceId;

  /// The client address the session observed, when known.
  final String? ip;

  /// The op name.
  final String op;

  /// JSON array of the argument names, sorted.
  final String argNames;

  /// An `AuditOutcome` name: `ok`, `denied` or `failed`.
  final String outcome;

  /// When the call ended.
  final DateTime createdAt;
  const ServerAuditTableData({
    required this.id,
    required this.userId,
    this.deviceId,
    this.ip,
    required this.op,
    required this.argNames,
    required this.outcome,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || ip != null) {
      map['ip'] = Variable<String>(ip);
    }
    map['op'] = Variable<String>(op);
    map['arg_names'] = Variable<String>(argNames);
    map['outcome'] = Variable<String>(outcome);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ServerAuditTableCompanion toCompanion(bool nullToAbsent) {
    return ServerAuditTableCompanion(
      id: Value(id),
      userId: Value(userId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      ip: ip == null && nullToAbsent ? const Value.absent() : Value(ip),
      op: Value(op),
      argNames: Value(argNames),
      outcome: Value(outcome),
      createdAt: Value(createdAt),
    );
  }

  factory ServerAuditTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerAuditTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      ip: serializer.fromJson<String?>(json['ip']),
      op: serializer.fromJson<String>(json['op']),
      argNames: serializer.fromJson<String>(json['argNames']),
      outcome: serializer.fromJson<String>(json['outcome']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'ip': serializer.toJson<String?>(ip),
      'op': serializer.toJson<String>(op),
      'argNames': serializer.toJson<String>(argNames),
      'outcome': serializer.toJson<String>(outcome),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ServerAuditTableData copyWith({
    String? id,
    String? userId,
    Value<String?> deviceId = const Value.absent(),
    Value<String?> ip = const Value.absent(),
    String? op,
    String? argNames,
    String? outcome,
    DateTime? createdAt,
  }) => ServerAuditTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    ip: ip.present ? ip.value : this.ip,
    op: op ?? this.op,
    argNames: argNames ?? this.argNames,
    outcome: outcome ?? this.outcome,
    createdAt: createdAt ?? this.createdAt,
  );
  ServerAuditTableData copyWithCompanion(ServerAuditTableCompanion data) {
    return ServerAuditTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      ip: data.ip.present ? data.ip.value : this.ip,
      op: data.op.present ? data.op.value : this.op,
      argNames: data.argNames.present ? data.argNames.value : this.argNames,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerAuditTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('ip: $ip, ')
          ..write('op: $op, ')
          ..write('argNames: $argNames, ')
          ..write('outcome: $outcome, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, deviceId, ip, op, argNames, outcome, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerAuditTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.ip == this.ip &&
          other.op == this.op &&
          other.argNames == this.argNames &&
          other.outcome == this.outcome &&
          other.createdAt == this.createdAt);
}

class ServerAuditTableCompanion extends UpdateCompanion<ServerAuditTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> deviceId;
  final Value<String?> ip;
  final Value<String> op;
  final Value<String> argNames;
  final Value<String> outcome;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ServerAuditTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.ip = const Value.absent(),
    this.op = const Value.absent(),
    this.argNames = const Value.absent(),
    this.outcome = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServerAuditTableCompanion.insert({
    required String id,
    required String userId,
    this.deviceId = const Value.absent(),
    this.ip = const Value.absent(),
    required String op,
    required String argNames,
    required String outcome,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       op = Value(op),
       argNames = Value(argNames),
       outcome = Value(outcome),
       createdAt = Value(createdAt);
  static Insertable<ServerAuditTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<String>? ip,
    Expression<String>? op,
    Expression<String>? argNames,
    Expression<String>? outcome,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (ip != null) 'ip': ip,
      if (op != null) 'op': op,
      if (argNames != null) 'arg_names': argNames,
      if (outcome != null) 'outcome': outcome,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServerAuditTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? deviceId,
    Value<String?>? ip,
    Value<String>? op,
    Value<String>? argNames,
    Value<String>? outcome,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ServerAuditTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      ip: ip ?? this.ip,
      op: op ?? this.op,
      argNames: argNames ?? this.argNames,
      outcome: outcome ?? this.outcome,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (ip.present) {
      map['ip'] = Variable<String>(ip.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (argNames.present) {
      map['arg_names'] = Variable<String>(argNames.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServerAuditTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('ip: $ip, ')
          ..write('op: $op, ')
          ..write('argNames: $argNames, ')
          ..write('outcome: $outcome, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServerNoticesTableTable extends ServerNoticesTable
    with TableInfo<$ServerNoticesTableTable, ServerNoticesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServerNoticesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(PlatformStoredValues.serverNoticeKind),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, subject, detail, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'server_notices';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerNoticesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    } else if (isInserting) {
      context.missing(_detailMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, subject};
  @override
  ServerNoticesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerNoticesTableData(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ServerNoticesTableTable createAlias(String alias) {
    return $ServerNoticesTableTable(attachedDatabase, alias);
  }
}

class ServerNoticesTableData extends DataClass
    implements Insertable<ServerNoticesTableData> {
  /// What it is about: a `ServerNoticeKind` wire name.
  final String kind;

  /// The thing it names (a workspace id). No foreign key: a notice is kept
  /// until it is resolved, whatever happened to what it names.
  final String subject;

  /// The operator-facing finding.
  final String detail;

  /// When it was first raised.
  final DateTime createdAt;
  const ServerNoticesTableData({
    required this.kind,
    required this.subject,
    required this.detail,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['subject'] = Variable<String>(subject);
    map['detail'] = Variable<String>(detail);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ServerNoticesTableCompanion toCompanion(bool nullToAbsent) {
    return ServerNoticesTableCompanion(
      kind: Value(kind),
      subject: Value(subject),
      detail: Value(detail),
      createdAt: Value(createdAt),
    );
  }

  factory ServerNoticesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerNoticesTableData(
      kind: serializer.fromJson<String>(json['kind']),
      subject: serializer.fromJson<String>(json['subject']),
      detail: serializer.fromJson<String>(json['detail']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'subject': serializer.toJson<String>(subject),
      'detail': serializer.toJson<String>(detail),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ServerNoticesTableData copyWith({
    String? kind,
    String? subject,
    String? detail,
    DateTime? createdAt,
  }) => ServerNoticesTableData(
    kind: kind ?? this.kind,
    subject: subject ?? this.subject,
    detail: detail ?? this.detail,
    createdAt: createdAt ?? this.createdAt,
  );
  ServerNoticesTableData copyWithCompanion(ServerNoticesTableCompanion data) {
    return ServerNoticesTableData(
      kind: data.kind.present ? data.kind.value : this.kind,
      subject: data.subject.present ? data.subject.value : this.subject,
      detail: data.detail.present ? data.detail.value : this.detail,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerNoticesTableData(')
          ..write('kind: $kind, ')
          ..write('subject: $subject, ')
          ..write('detail: $detail, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, subject, detail, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerNoticesTableData &&
          other.kind == this.kind &&
          other.subject == this.subject &&
          other.detail == this.detail &&
          other.createdAt == this.createdAt);
}

class ServerNoticesTableCompanion
    extends UpdateCompanion<ServerNoticesTableData> {
  final Value<String> kind;
  final Value<String> subject;
  final Value<String> detail;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ServerNoticesTableCompanion({
    this.kind = const Value.absent(),
    this.subject = const Value.absent(),
    this.detail = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServerNoticesTableCompanion.insert({
    required String kind,
    required String subject,
    required String detail,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       subject = Value(subject),
       detail = Value(detail),
       createdAt = Value(createdAt);
  static Insertable<ServerNoticesTableData> custom({
    Expression<String>? kind,
    Expression<String>? subject,
    Expression<String>? detail,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (subject != null) 'subject': subject,
      if (detail != null) 'detail': detail,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServerNoticesTableCompanion copyWith({
    Value<String>? kind,
    Value<String>? subject,
    Value<String>? detail,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ServerNoticesTableCompanion(
      kind: kind ?? this.kind,
      subject: subject ?? this.subject,
      detail: detail ?? this.detail,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServerNoticesTableCompanion(')
          ..write('kind: $kind, ')
          ..write('subject: $subject, ')
          ..write('detail: $detail, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentPullRequestRequestersTableTable
    extends AgentPullRequestRequestersTable
    with
        TableInfo<
          $AgentPullRequestRequestersTableTable,
          AgentPullRequestRequestersTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentPullRequestRequestersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    check: () => state.isIn(PlatformStoredValues.agentPullRequestRecordState),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prKeyMeta = const VerificationMeta('prKey');
  @override
  late final GeneratedColumn<String> prKey = GeneratedColumn<String>(
    'pr_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [state, prKey, userId, recordedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_pull_request_requesters';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentPullRequestRequestersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('pr_key')) {
      context.handle(
        _prKeyMeta,
        prKey.isAcceptableOrUnknown(data['pr_key']!, _prKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_prKeyMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {state, prKey, userId};
  @override
  AgentPullRequestRequestersTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentPullRequestRequestersTableData(
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      prKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pr_key'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $AgentPullRequestRequestersTableTable createAlias(String alias) {
    return $AgentPullRequestRequestersTableTable(attachedDatabase, alias);
  }
}

class AgentPullRequestRequestersTableData extends DataClass
    implements Insertable<AgentPullRequestRequestersTableData> {
  /// `opened` (keyed by number) or `pending` (keyed by head branch): an
  /// `AgentPullRequestRecordState` wire name.
  final String state;

  /// The pull request's forge key.
  final String prKey;

  /// A person who may not approve it; the refusal is theirs and goes with
  /// them.
  final String userId;

  /// When this person was last recorded on it.
  final DateTime recordedAt;
  const AgentPullRequestRequestersTableData({
    required this.state,
    required this.prKey,
    required this.userId,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['state'] = Variable<String>(state);
    map['pr_key'] = Variable<String>(prKey);
    map['user_id'] = Variable<String>(userId);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  AgentPullRequestRequestersTableCompanion toCompanion(bool nullToAbsent) {
    return AgentPullRequestRequestersTableCompanion(
      state: Value(state),
      prKey: Value(prKey),
      userId: Value(userId),
      recordedAt: Value(recordedAt),
    );
  }

  factory AgentPullRequestRequestersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentPullRequestRequestersTableData(
      state: serializer.fromJson<String>(json['state']),
      prKey: serializer.fromJson<String>(json['prKey']),
      userId: serializer.fromJson<String>(json['userId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'state': serializer.toJson<String>(state),
      'prKey': serializer.toJson<String>(prKey),
      'userId': serializer.toJson<String>(userId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  AgentPullRequestRequestersTableData copyWith({
    String? state,
    String? prKey,
    String? userId,
    DateTime? recordedAt,
  }) => AgentPullRequestRequestersTableData(
    state: state ?? this.state,
    prKey: prKey ?? this.prKey,
    userId: userId ?? this.userId,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  AgentPullRequestRequestersTableData copyWithCompanion(
    AgentPullRequestRequestersTableCompanion data,
  ) {
    return AgentPullRequestRequestersTableData(
      state: data.state.present ? data.state.value : this.state,
      prKey: data.prKey.present ? data.prKey.value : this.prKey,
      userId: data.userId.present ? data.userId.value : this.userId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentPullRequestRequestersTableData(')
          ..write('state: $state, ')
          ..write('prKey: $prKey, ')
          ..write('userId: $userId, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(state, prKey, userId, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentPullRequestRequestersTableData &&
          other.state == this.state &&
          other.prKey == this.prKey &&
          other.userId == this.userId &&
          other.recordedAt == this.recordedAt);
}

class AgentPullRequestRequestersTableCompanion
    extends UpdateCompanion<AgentPullRequestRequestersTableData> {
  final Value<String> state;
  final Value<String> prKey;
  final Value<String> userId;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const AgentPullRequestRequestersTableCompanion({
    this.state = const Value.absent(),
    this.prKey = const Value.absent(),
    this.userId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentPullRequestRequestersTableCompanion.insert({
    required String state,
    required String prKey,
    required String userId,
    required DateTime recordedAt,
    this.rowid = const Value.absent(),
  }) : state = Value(state),
       prKey = Value(prKey),
       userId = Value(userId),
       recordedAt = Value(recordedAt);
  static Insertable<AgentPullRequestRequestersTableData> custom({
    Expression<String>? state,
    Expression<String>? prKey,
    Expression<String>? userId,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (state != null) 'state': state,
      if (prKey != null) 'pr_key': prKey,
      if (userId != null) 'user_id': userId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentPullRequestRequestersTableCompanion copyWith({
    Value<String>? state,
    Value<String>? prKey,
    Value<String>? userId,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return AgentPullRequestRequestersTableCompanion(
      state: state ?? this.state,
      prKey: prKey ?? this.prKey,
      userId: userId ?? this.userId,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (prKey.present) {
      map['pr_key'] = Variable<String>(prKey.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentPullRequestRequestersTableCompanion(')
          ..write('state: $state, ')
          ..write('prKey: $prKey, ')
          ..write('userId: $userId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$GlobalDatabase extends GeneratedDatabase {
  _$GlobalDatabase(QueryExecutor e) : super(e);
  $GlobalDatabaseManager get managers => $GlobalDatabaseManager(this);
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final $WorkspacesTableTable workspacesTable = $WorkspacesTableTable(
    this,
  );
  late final $UserPreferencesTableTable userPreferencesTable =
      $UserPreferencesTableTable(this);
  late final $PairedDevicesTableTable pairedDevicesTable =
      $PairedDevicesTableTable(this);
  late final $RssFeedsTableTable rssFeedsTable = $RssFeedsTableTable(this);
  late final $RssArticlesTableTable rssArticlesTable = $RssArticlesTableTable(
    this,
  );
  late final $WorkersTableTable workersTable = $WorkersTableTable(this);
  late final $JobsTableTable jobsTable = $JobsTableTable(this);
  late final $PlacementLogTableTable placementLogTable =
      $PlacementLogTableTable(this);
  late final $WorkspaceRoutesTableTable workspaceRoutesTable =
      $WorkspaceRoutesTableTable(this);
  late final $InviteSecureRoutesTableTable inviteSecureRoutesTable =
      $InviteSecureRoutesTableTable(this);
  late final $ServerMetaTableTable serverMetaTable = $ServerMetaTableTable(
    this,
  );
  late final $ServerSettingsTableTable serverSettingsTable =
      $ServerSettingsTableTable(this);
  late final $SsoConnectionsTableTable ssoConnectionsTable =
      $SsoConnectionsTableTable(this);
  late final $ManagedActionPoliciesTableTable managedActionPoliciesTable =
      $ManagedActionPoliciesTableTable(this);
  late final $EnvironmentSlotLeasesTableTable environmentSlotLeasesTable =
      $EnvironmentSlotLeasesTableTable(this);
  late final $ServerAuditTableTable serverAuditTable = $ServerAuditTableTable(
    this,
  );
  late final $ServerNoticesTableTable serverNoticesTable =
      $ServerNoticesTableTable(this);
  late final $AgentPullRequestRequestersTableTable
  agentPullRequestRequestersTable = $AgentPullRequestRequestersTableTable(this);
  late final Index idxWorkspacesOwner = Index(
    'idx_workspaces_owner',
    'CREATE INDEX idx_workspaces_owner ON workspaces (owner_user_id)',
  );
  late final Index idxUsersHandle = Index(
    'idx_users_handle',
    'CREATE UNIQUE INDEX idx_users_handle ON users (handle)',
  );
  late final Index idxUsersSsoSubject = Index(
    'idx_users_sso_subject',
    'CREATE UNIQUE INDEX idx_users_sso_subject ON users (sso_issuer, sso_subject) WHERE sso_issuer IS NOT NULL AND sso_subject IS NOT NULL',
  );
  late final Index idxPairedDevicesUser = Index(
    'idx_paired_devices_user',
    'CREATE INDEX idx_paired_devices_user ON paired_devices (user_id)',
  );
  late final Index idxPairedDevicesLandingWorkspace = Index(
    'idx_paired_devices_landing_workspace',
    'CREATE INDEX idx_paired_devices_landing_workspace ON paired_devices (landing_workspace_id)',
  );
  late final Index uqRssFeedsUserUrl = Index(
    'uq_rss_feeds_user_url',
    'CREATE UNIQUE INDEX uq_rss_feeds_user_url ON rss_feeds (user_id, url)',
  );
  late final Index idxRssArticlesFeedIdGuid = Index(
    'idx_rss_articles_feedId_guid',
    'CREATE UNIQUE INDEX idx_rss_articles_feedId_guid ON rss_articles (feed_id, guid)',
  );
  late final Index idxRssArticlesFeedPublished = Index(
    'idx_rss_articles_feed_published',
    'CREATE INDEX idx_rss_articles_feed_published ON rss_articles (feed_id, COALESCE(published_at, created_at) DESC, id DESC)',
  );
  late final Index idxWorkersStatus = Index(
    'idx_workers_status',
    'CREATE INDEX idx_workers_status ON workers (status)',
  );
  late final Index idxWorkersPairedDevice = Index(
    'idx_workers_paired_device',
    'CREATE INDEX idx_workers_paired_device ON workers (paired_device_id)',
  );
  late final Index idxWorkersRegisteredBy = Index(
    'idx_workers_registered_by',
    'CREATE INDEX idx_workers_registered_by ON workers (registered_by)',
  );
  late final Index idxJobsWorkspaceStatus = Index(
    'idx_jobs_workspace_status',
    'CREATE INDEX idx_jobs_workspace_status ON jobs (workspace_id, status)',
  );
  late final Index idxJobsWorkerStatus = Index(
    'idx_jobs_worker_status',
    'CREATE INDEX idx_jobs_worker_status ON jobs (worker_id, status)',
  );
  late final Index idxJobsLeaseExpiry = Index(
    'idx_jobs_lease_expiry',
    'CREATE INDEX idx_jobs_lease_expiry ON jobs (lease_expires_at)',
  );
  late final Index idxJobsStatusFinished = Index(
    'idx_jobs_status_finished',
    'CREATE INDEX idx_jobs_status_finished ON jobs (status, finished_at)',
  );
  late final Index idxJobsSubmittedBy = Index(
    'idx_jobs_submitted_by',
    'CREATE INDEX idx_jobs_submitted_by ON jobs (submitted_by)',
  );
  late final Index idxPlacementLogJob = Index(
    'idx_placement_log_job',
    'CREATE INDEX idx_placement_log_job ON placement_log (job_id)',
  );
  late final Index idxPlacementLogWorkspace = Index(
    'idx_placement_log_workspace',
    'CREATE INDEX idx_placement_log_workspace ON placement_log (workspace_id)',
  );
  late final Index idxPlacementLogWorker = Index(
    'idx_placement_log_worker',
    'CREATE INDEX idx_placement_log_worker ON placement_log (worker_id)',
  );
  late final Index idxPlacementLogCreated = Index(
    'idx_placement_log_created',
    'CREATE INDEX idx_placement_log_created ON placement_log (created_at)',
  );
  late final Index idxWorkspaceRoutesWorkspace = Index(
    'idx_workspace_routes_workspace',
    'CREATE INDEX idx_workspace_routes_workspace ON workspace_routes (workspace_id)',
  );
  late final Index idxInviteSecureRoutesWorkspace = Index(
    'idx_invite_secure_routes_workspace',
    'CREATE INDEX idx_invite_secure_routes_workspace ON invite_secure_routes (workspace_id)',
  );
  late final Index uqManagedActionPoliciesClass = Index(
    'uq_managed_action_policies_class',
    'CREATE UNIQUE INDEX uq_managed_action_policies_class ON managed_action_policies (action_class) WHERE action_class IS NOT NULL',
  );
  late final Index uqManagedActionPoliciesCommand = Index(
    'uq_managed_action_policies_command',
    'CREATE UNIQUE INDEX uq_managed_action_policies_command ON managed_action_policies (command_prefix) WHERE command_prefix IS NOT NULL',
  );
  late final Index idxManagedActionPoliciesUpdatedBy = Index(
    'idx_managed_action_policies_updated_by',
    'CREATE INDEX idx_managed_action_policies_updated_by ON managed_action_policies (updated_by)',
  );
  late final Index idxServerAuditCreated = Index(
    'idx_server_audit_created',
    'CREATE INDEX idx_server_audit_created ON server_audit (created_at)',
  );
  late final Index idxAgentPullRequestRequestersUser = Index(
    'idx_agent_pull_request_requesters_user',
    'CREATE INDEX idx_agent_pull_request_requesters_user ON agent_pull_request_requesters (user_id)',
  );
  late final WorkspaceRegistryDao workspaceRegistryDao = WorkspaceRegistryDao(
    this as GlobalDatabase,
  );
  late final UserDao userDao = UserDao(this as GlobalDatabase);
  late final UserPreferenceDao userPreferenceDao = UserPreferenceDao(
    this as GlobalDatabase,
  );
  late final PairedDeviceDao pairedDeviceDao = PairedDeviceDao(
    this as GlobalDatabase,
  );
  late final RssDao rssDao = RssDao(this as GlobalDatabase);
  late final FleetDao fleetDao = FleetDao(this as GlobalDatabase);
  late final WorkspaceRouteDao workspaceRouteDao = WorkspaceRouteDao(
    this as GlobalDatabase,
  );
  late final ServerSettingDao serverSettingDao = ServerSettingDao(
    this as GlobalDatabase,
  );
  late final SsoConnectionDao ssoConnectionDao = SsoConnectionDao(
    this as GlobalDatabase,
  );
  late final ManagedActionPolicyDao managedActionPolicyDao =
      ManagedActionPolicyDao(this as GlobalDatabase);
  late final EnvironmentLeaseDao environmentLeaseDao = EnvironmentLeaseDao(
    this as GlobalDatabase,
  );
  late final ServerAuditDao serverAuditDao = ServerAuditDao(
    this as GlobalDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usersTable,
    workspacesTable,
    userPreferencesTable,
    pairedDevicesTable,
    rssFeedsTable,
    rssArticlesTable,
    workersTable,
    jobsTable,
    placementLogTable,
    workspaceRoutesTable,
    inviteSecureRoutesTable,
    serverMetaTable,
    serverSettingsTable,
    ssoConnectionsTable,
    managedActionPoliciesTable,
    environmentSlotLeasesTable,
    serverAuditTable,
    serverNoticesTable,
    agentPullRequestRequestersTable,
    idxWorkspacesOwner,
    idxUsersHandle,
    idxUsersSsoSubject,
    idxPairedDevicesUser,
    idxPairedDevicesLandingWorkspace,
    uqRssFeedsUserUrl,
    idxRssArticlesFeedIdGuid,
    idxRssArticlesFeedPublished,
    idxWorkersStatus,
    idxWorkersPairedDevice,
    idxWorkersRegisteredBy,
    idxJobsWorkspaceStatus,
    idxJobsWorkerStatus,
    idxJobsLeaseExpiry,
    idxJobsStatusFinished,
    idxJobsSubmittedBy,
    idxPlacementLogJob,
    idxPlacementLogWorkspace,
    idxPlacementLogWorker,
    idxPlacementLogCreated,
    idxWorkspaceRoutesWorkspace,
    idxInviteSecureRoutesWorkspace,
    uqManagedActionPoliciesClass,
    uqManagedActionPoliciesCommand,
    idxManagedActionPoliciesUpdatedBy,
    idxServerAuditCreated,
    idxAgentPullRequestRequestersUser,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_preferences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('paired_devices', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('paired_devices', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rss_feeds', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rss_feeds',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rss_articles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'paired_devices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workers', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workers', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('jobs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('jobs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('jobs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('placement_log', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'jobs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('placement_log', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('placement_log', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workspace_routes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('invite_secure_routes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('managed_action_policies', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('environment_slot_leases', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('agent_pull_request_requesters', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$UsersTableTableCreateCompanionBuilder =
    UsersTableCompanion Function({
      required String id,
      required String handle,
      required String displayName,
      Value<String?> email,
      Value<bool> emailVerified,
      Value<String?> avatarRef,
      Value<String?> gitAuthorName,
      Value<String?> gitAuthorEmail,
      Value<String?> ssoSubject,
      Value<String?> ssoIssuer,
      Value<DateTime?> deactivatedAt,
      Value<DateTime?> onboardingFinishedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$UsersTableTableUpdateCompanionBuilder =
    UsersTableCompanion Function({
      Value<String> id,
      Value<String> handle,
      Value<String> displayName,
      Value<String?> email,
      Value<bool> emailVerified,
      Value<String?> avatarRef,
      Value<String?> gitAuthorName,
      Value<String?> gitAuthorEmail,
      Value<String?> ssoSubject,
      Value<String?> ssoIssuer,
      Value<DateTime?> deactivatedAt,
      Value<DateTime?> onboardingFinishedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$UsersTableTableReferences
    extends BaseReferences<_$GlobalDatabase, $UsersTableTable, UsersTableData> {
  $$UsersTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkspacesTableTable, List<WorkspacesTableData>>
  _workspacesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workspacesTable,
        aliasName: 'users__id__workspaces__owner_user_id',
      );

  $$WorkspacesTableTableProcessedTableManager get workspacesTableRefs {
    final manager = $$WorkspacesTableTableTableManager(
      $_db,
      $_db.workspacesTable,
    ).filter((f) => f.ownerUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workspacesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $UserPreferencesTableTable,
    List<UserPreferencesTableData>
  >
  _userPreferencesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userPreferencesTable,
        aliasName: 'users__id__user_preferences__user_id',
      );

  $$UserPreferencesTableTableProcessedTableManager
  get userPreferencesTableRefs {
    final manager = $$UserPreferencesTableTableTableManager(
      $_db,
      $_db.userPreferencesTable,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userPreferencesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PairedDevicesTableTable,
    List<PairedDevicesTableData>
  >
  _pairedDevicesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pairedDevicesTable,
        aliasName: 'users__id__paired_devices__user_id',
      );

  $$PairedDevicesTableTableProcessedTableManager get pairedDevicesTableRefs {
    final manager = $$PairedDevicesTableTableTableManager(
      $_db,
      $_db.pairedDevicesTable,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pairedDevicesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RssFeedsTableTable, List<RssFeedsTableData>>
  _rssFeedsTableRefsTable(_$GlobalDatabase db) => MultiTypedResultKey.fromTable(
    db.rssFeedsTable,
    aliasName: 'users__id__rss_feeds__user_id',
  );

  $$RssFeedsTableTableProcessedTableManager get rssFeedsTableRefs {
    final manager = $$RssFeedsTableTableTableManager(
      $_db,
      $_db.rssFeedsTable,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rssFeedsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkersTableTable, List<WorkersTableData>>
  _workersTableRefsTable(_$GlobalDatabase db) => MultiTypedResultKey.fromTable(
    db.workersTable,
    aliasName: 'users__id__workers__registered_by',
  );

  $$WorkersTableTableProcessedTableManager get workersTableRefs {
    final manager = $$WorkersTableTableTableManager(
      $_db,
      $_db.workersTable,
    ).filter((f) => f.registeredBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workersTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JobsTableTable, List<JobsTableData>>
  _jobsTableRefsTable(_$GlobalDatabase db) => MultiTypedResultKey.fromTable(
    db.jobsTable,
    aliasName: 'users__id__jobs__submitted_by',
  );

  $$JobsTableTableProcessedTableManager get jobsTableRefs {
    final manager = $$JobsTableTableTableManager(
      $_db,
      $_db.jobsTable,
    ).filter((f) => f.submittedBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_jobsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ManagedActionPoliciesTableTable,
    List<ManagedActionPoliciesTableData>
  >
  _managedActionPoliciesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.managedActionPoliciesTable,
        aliasName: 'users__id__managed_action_policies__updated_by',
      );

  $$ManagedActionPoliciesTableTableProcessedTableManager
  get managedActionPoliciesTableRefs {
    final manager = $$ManagedActionPoliciesTableTableTableManager(
      $_db,
      $_db.managedActionPoliciesTable,
    ).filter((f) => f.updatedBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _managedActionPoliciesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AgentPullRequestRequestersTableTable,
    List<AgentPullRequestRequestersTableData>
  >
  _agentPullRequestRequestersTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.agentPullRequestRequestersTable,
        aliasName: 'users__id__agent_pull_request_requesters__user_id',
      );

  $$AgentPullRequestRequestersTableTableProcessedTableManager
  get agentPullRequestRequestersTableRefs {
    final manager = $$AgentPullRequestRequestersTableTableTableManager(
      $_db,
      $_db.agentPullRequestRequestersTable,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _agentPullRequestRequestersTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $UsersTableTable> {
  $$UsersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarRef => $composableBuilder(
    column: $table.avatarRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gitAuthorName => $composableBuilder(
    column: $table.gitAuthorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gitAuthorEmail => $composableBuilder(
    column: $table.gitAuthorEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ssoSubject => $composableBuilder(
    column: $table.ssoSubject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ssoIssuer => $composableBuilder(
    column: $table.ssoIssuer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get onboardingFinishedAt => $composableBuilder(
    column: $table.onboardingFinishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workspacesTableRefs(
    Expression<bool> Function($$WorkspacesTableTableFilterComposer f) f,
  ) {
    final $$WorkspacesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.ownerUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableFilterComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userPreferencesTableRefs(
    Expression<bool> Function($$UserPreferencesTableTableFilterComposer f) f,
  ) {
    final $$UserPreferencesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPreferencesTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPreferencesTableTableFilterComposer(
            $db: $db,
            $table: $db.userPreferencesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pairedDevicesTableRefs(
    Expression<bool> Function($$PairedDevicesTableTableFilterComposer f) f,
  ) {
    final $$PairedDevicesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pairedDevicesTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PairedDevicesTableTableFilterComposer(
            $db: $db,
            $table: $db.pairedDevicesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rssFeedsTableRefs(
    Expression<bool> Function($$RssFeedsTableTableFilterComposer f) f,
  ) {
    final $$RssFeedsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableFilterComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workersTableRefs(
    Expression<bool> Function($$WorkersTableTableFilterComposer f) f,
  ) {
    final $$WorkersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.registeredBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableFilterComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> jobsTableRefs(
    Expression<bool> Function($$JobsTableTableFilterComposer f) f,
  ) {
    final $$JobsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobsTable,
      getReferencedColumn: (t) => t.submittedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableTableFilterComposer(
            $db: $db,
            $table: $db.jobsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> managedActionPoliciesTableRefs(
    Expression<bool> Function($$ManagedActionPoliciesTableTableFilterComposer f)
    f,
  ) {
    final $$ManagedActionPoliciesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.managedActionPoliciesTable,
          getReferencedColumn: (t) => t.updatedBy,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ManagedActionPoliciesTableTableFilterComposer(
                $db: $db,
                $table: $db.managedActionPoliciesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> agentPullRequestRequestersTableRefs(
    Expression<bool> Function(
      $$AgentPullRequestRequestersTableTableFilterComposer f,
    )
    f,
  ) {
    final $$AgentPullRequestRequestersTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.agentPullRequestRequestersTable,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AgentPullRequestRequestersTableTableFilterComposer(
                $db: $db,
                $table: $db.agentPullRequestRequestersTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UsersTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $UsersTableTable> {
  $$UsersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarRef => $composableBuilder(
    column: $table.avatarRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gitAuthorName => $composableBuilder(
    column: $table.gitAuthorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gitAuthorEmail => $composableBuilder(
    column: $table.gitAuthorEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ssoSubject => $composableBuilder(
    column: $table.ssoSubject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ssoIssuer => $composableBuilder(
    column: $table.ssoIssuer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get onboardingFinishedAt => $composableBuilder(
    column: $table.onboardingFinishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $UsersTableTable> {
  $$UsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get handle =>
      $composableBuilder(column: $table.handle, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<bool> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarRef =>
      $composableBuilder(column: $table.avatarRef, builder: (column) => column);

  GeneratedColumn<String> get gitAuthorName => $composableBuilder(
    column: $table.gitAuthorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gitAuthorEmail => $composableBuilder(
    column: $table.gitAuthorEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ssoSubject => $composableBuilder(
    column: $table.ssoSubject,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ssoIssuer =>
      $composableBuilder(column: $table.ssoIssuer, builder: (column) => column);

  GeneratedColumn<DateTime> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get onboardingFinishedAt => $composableBuilder(
    column: $table.onboardingFinishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> workspacesTableRefs<T extends Object>(
    Expression<T> Function($$WorkspacesTableTableAnnotationComposer a) f,
  ) {
    final $$WorkspacesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.ownerUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userPreferencesTableRefs<T extends Object>(
    Expression<T> Function($$UserPreferencesTableTableAnnotationComposer a) f,
  ) {
    final $$UserPreferencesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userPreferencesTable,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserPreferencesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.userPreferencesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> pairedDevicesTableRefs<T extends Object>(
    Expression<T> Function($$PairedDevicesTableTableAnnotationComposer a) f,
  ) {
    final $$PairedDevicesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.pairedDevicesTable,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PairedDevicesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.pairedDevicesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> rssFeedsTableRefs<T extends Object>(
    Expression<T> Function($$RssFeedsTableTableAnnotationComposer a) f,
  ) {
    final $$RssFeedsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workersTableRefs<T extends Object>(
    Expression<T> Function($$WorkersTableTableAnnotationComposer a) f,
  ) {
    final $$WorkersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.registeredBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> jobsTableRefs<T extends Object>(
    Expression<T> Function($$JobsTableTableAnnotationComposer a) f,
  ) {
    final $$JobsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobsTable,
      getReferencedColumn: (t) => t.submittedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.jobsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> managedActionPoliciesTableRefs<T extends Object>(
    Expression<T> Function(
      $$ManagedActionPoliciesTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$ManagedActionPoliciesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.managedActionPoliciesTable,
          getReferencedColumn: (t) => t.updatedBy,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ManagedActionPoliciesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.managedActionPoliciesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> agentPullRequestRequestersTableRefs<T extends Object>(
    Expression<T> Function(
      $$AgentPullRequestRequestersTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$AgentPullRequestRequestersTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.agentPullRequestRequestersTable,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AgentPullRequestRequestersTableTableAnnotationComposer(
                $db: $db,
                $table: $db.agentPullRequestRequestersTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UsersTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $UsersTableTable,
          UsersTableData,
          $$UsersTableTableFilterComposer,
          $$UsersTableTableOrderingComposer,
          $$UsersTableTableAnnotationComposer,
          $$UsersTableTableCreateCompanionBuilder,
          $$UsersTableTableUpdateCompanionBuilder,
          (UsersTableData, $$UsersTableTableReferences),
          UsersTableData,
          PrefetchHooks Function({
            bool workspacesTableRefs,
            bool userPreferencesTableRefs,
            bool pairedDevicesTableRefs,
            bool rssFeedsTableRefs,
            bool workersTableRefs,
            bool jobsTableRefs,
            bool managedActionPoliciesTableRefs,
            bool agentPullRequestRequestersTableRefs,
          })
        > {
  $$UsersTableTableTableManager(_$GlobalDatabase db, $UsersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> handle = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<bool> emailVerified = const Value.absent(),
                Value<String?> avatarRef = const Value.absent(),
                Value<String?> gitAuthorName = const Value.absent(),
                Value<String?> gitAuthorEmail = const Value.absent(),
                Value<String?> ssoSubject = const Value.absent(),
                Value<String?> ssoIssuer = const Value.absent(),
                Value<DateTime?> deactivatedAt = const Value.absent(),
                Value<DateTime?> onboardingFinishedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion(
                id: id,
                handle: handle,
                displayName: displayName,
                email: email,
                emailVerified: emailVerified,
                avatarRef: avatarRef,
                gitAuthorName: gitAuthorName,
                gitAuthorEmail: gitAuthorEmail,
                ssoSubject: ssoSubject,
                ssoIssuer: ssoIssuer,
                deactivatedAt: deactivatedAt,
                onboardingFinishedAt: onboardingFinishedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String handle,
                required String displayName,
                Value<String?> email = const Value.absent(),
                Value<bool> emailVerified = const Value.absent(),
                Value<String?> avatarRef = const Value.absent(),
                Value<String?> gitAuthorName = const Value.absent(),
                Value<String?> gitAuthorEmail = const Value.absent(),
                Value<String?> ssoSubject = const Value.absent(),
                Value<String?> ssoIssuer = const Value.absent(),
                Value<DateTime?> deactivatedAt = const Value.absent(),
                Value<DateTime?> onboardingFinishedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion.insert(
                id: id,
                handle: handle,
                displayName: displayName,
                email: email,
                emailVerified: emailVerified,
                avatarRef: avatarRef,
                gitAuthorName: gitAuthorName,
                gitAuthorEmail: gitAuthorEmail,
                ssoSubject: ssoSubject,
                ssoIssuer: ssoIssuer,
                deactivatedAt: deactivatedAt,
                onboardingFinishedAt: onboardingFinishedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsersTableTable, UsersTableData>(table),
                  $$UsersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspacesTableRefs = false,
                userPreferencesTableRefs = false,
                pairedDevicesTableRefs = false,
                rssFeedsTableRefs = false,
                workersTableRefs = false,
                jobsTableRefs = false,
                managedActionPoliciesTableRefs = false,
                agentPullRequestRequestersTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workspacesTableRefs) db.workspacesTable,
                    if (userPreferencesTableRefs) db.userPreferencesTable,
                    if (pairedDevicesTableRefs) db.pairedDevicesTable,
                    if (rssFeedsTableRefs) db.rssFeedsTable,
                    if (workersTableRefs) db.workersTable,
                    if (jobsTableRefs) db.jobsTable,
                    if (managedActionPoliciesTableRefs)
                      db.managedActionPoliciesTable,
                    if (agentPullRequestRequestersTableRefs)
                      db.agentPullRequestRequestersTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workspacesTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          WorkspacesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._workspacesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).workspacesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerUserId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userPreferencesTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          UserPreferencesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._userPreferencesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).userPreferencesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pairedDevicesTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          PairedDevicesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._pairedDevicesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).pairedDevicesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rssFeedsTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          RssFeedsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._rssFeedsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).rssFeedsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workersTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          WorkersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._workersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).workersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.registeredBy == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (jobsTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          JobsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._jobsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).jobsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.submittedBy == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (managedActionPoliciesTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          ManagedActionPoliciesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._managedActionPoliciesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).managedActionPoliciesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.updatedBy == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (agentPullRequestRequestersTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          AgentPullRequestRequestersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._agentPullRequestRequestersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).agentPullRequestRequestersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UsersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $UsersTableTable,
      UsersTableData,
      $$UsersTableTableFilterComposer,
      $$UsersTableTableOrderingComposer,
      $$UsersTableTableAnnotationComposer,
      $$UsersTableTableCreateCompanionBuilder,
      $$UsersTableTableUpdateCompanionBuilder,
      (UsersTableData, $$UsersTableTableReferences),
      UsersTableData,
      PrefetchHooks Function({
        bool workspacesTableRefs,
        bool userPreferencesTableRefs,
        bool pairedDevicesTableRefs,
        bool rssFeedsTableRefs,
        bool workersTableRefs,
        bool jobsTableRefs,
        bool managedActionPoliciesTableRefs,
        bool agentPullRequestRequestersTableRefs,
      })
    >;
typedef $$WorkspacesTableTableCreateCompanionBuilder =
    WorkspacesTableCompanion Function({
      required String id,
      required String name,
      Value<String?> logoPath,
      Value<String?> ownerUserId,
      Value<String> secretExcludeGlobs,
      Value<int> reviewConcurrency,
      Value<bool> autoPublishReview,
      Value<String> connectMode,
      Value<String> connectUrl,
      Value<String> githubAppId,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$WorkspacesTableTableUpdateCompanionBuilder =
    WorkspacesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> logoPath,
      Value<String?> ownerUserId,
      Value<String> secretExcludeGlobs,
      Value<int> reviewConcurrency,
      Value<bool> autoPublishReview,
      Value<String> connectMode,
      Value<String> connectUrl,
      Value<String> githubAppId,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$WorkspacesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $WorkspacesTableTable,
          WorkspacesTableData
        > {
  $$WorkspacesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _ownerUserIdTable(_$GlobalDatabase db) =>
      db.usersTable.createAlias('workspaces__owner_user_id__users__id');

  $$UsersTableTableProcessedTableManager? get ownerUserId {
    final $_column = $_itemColumn<String>('owner_user_id');
    if ($_column == null) return null;
    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $PairedDevicesTableTable,
    List<PairedDevicesTableData>
  >
  _pairedDevicesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pairedDevicesTable,
        aliasName: 'workspaces__id__paired_devices__landing_workspace_id',
      );

  $$PairedDevicesTableTableProcessedTableManager get pairedDevicesTableRefs {
    final manager =
        $$PairedDevicesTableTableTableManager(
          $_db,
          $_db.pairedDevicesTable,
        ).filter(
          (f) => f.landingWorkspaceId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _pairedDevicesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JobsTableTable, List<JobsTableData>>
  _jobsTableRefsTable(_$GlobalDatabase db) => MultiTypedResultKey.fromTable(
    db.jobsTable,
    aliasName: 'workspaces__id__jobs__workspace_id',
  );

  $$JobsTableTableProcessedTableManager get jobsTableRefs {
    final manager = $$JobsTableTableTableManager(
      $_db,
      $_db.jobsTable,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_jobsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PlacementLogTableTable,
    List<PlacementLogTableData>
  >
  _placementLogTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.placementLogTable,
        aliasName: 'workspaces__id__placement_log__workspace_id',
      );

  $$PlacementLogTableTableProcessedTableManager get placementLogTableRefs {
    final manager = $$PlacementLogTableTableTableManager(
      $_db,
      $_db.placementLogTable,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _placementLogTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $WorkspaceRoutesTableTable,
    List<WorkspaceRoutesTableData>
  >
  _workspaceRoutesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workspaceRoutesTable,
        aliasName: 'workspaces__id__workspace_routes__workspace_id',
      );

  $$WorkspaceRoutesTableTableProcessedTableManager
  get workspaceRoutesTableRefs {
    final manager = $$WorkspaceRoutesTableTableTableManager(
      $_db,
      $_db.workspaceRoutesTable,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workspaceRoutesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $InviteSecureRoutesTableTable,
    List<InviteSecureRoutesTableData>
  >
  _inviteSecureRoutesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.inviteSecureRoutesTable,
        aliasName: 'workspaces__id__invite_secure_routes__workspace_id',
      );

  $$InviteSecureRoutesTableTableProcessedTableManager
  get inviteSecureRoutesTableRefs {
    final manager = $$InviteSecureRoutesTableTableTableManager(
      $_db,
      $_db.inviteSecureRoutesTable,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inviteSecureRoutesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $EnvironmentSlotLeasesTableTable,
    List<EnvironmentSlotLeasesTableData>
  >
  _environmentSlotLeasesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.environmentSlotLeasesTable,
        aliasName: 'workspaces__id__environment_slot_leases__workspace_id',
      );

  $$EnvironmentSlotLeasesTableTableProcessedTableManager
  get environmentSlotLeasesTableRefs {
    final manager = $$EnvironmentSlotLeasesTableTableTableManager(
      $_db,
      $_db.environmentSlotLeasesTable,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _environmentSlotLeasesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkspacesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $WorkspacesTableTable> {
  $$WorkspacesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secretExcludeGlobs => $composableBuilder(
    column: $table.secretExcludeGlobs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewConcurrency => $composableBuilder(
    column: $table.reviewConcurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPublishReview => $composableBuilder(
    column: $table.autoPublishReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connectMode => $composableBuilder(
    column: $table.connectMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connectUrl => $composableBuilder(
    column: $table.connectUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get githubAppId => $composableBuilder(
    column: $table.githubAppId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get ownerUserId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUserId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> pairedDevicesTableRefs(
    Expression<bool> Function($$PairedDevicesTableTableFilterComposer f) f,
  ) {
    final $$PairedDevicesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pairedDevicesTable,
      getReferencedColumn: (t) => t.landingWorkspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PairedDevicesTableTableFilterComposer(
            $db: $db,
            $table: $db.pairedDevicesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> jobsTableRefs(
    Expression<bool> Function($$JobsTableTableFilterComposer f) f,
  ) {
    final $$JobsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobsTable,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableTableFilterComposer(
            $db: $db,
            $table: $db.jobsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> placementLogTableRefs(
    Expression<bool> Function($$PlacementLogTableTableFilterComposer f) f,
  ) {
    final $$PlacementLogTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placementLogTable,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacementLogTableTableFilterComposer(
            $db: $db,
            $table: $db.placementLogTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workspaceRoutesTableRefs(
    Expression<bool> Function($$WorkspaceRoutesTableTableFilterComposer f) f,
  ) {
    final $$WorkspaceRoutesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspaceRoutesTable,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspaceRoutesTableTableFilterComposer(
            $db: $db,
            $table: $db.workspaceRoutesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inviteSecureRoutesTableRefs(
    Expression<bool> Function($$InviteSecureRoutesTableTableFilterComposer f) f,
  ) {
    final $$InviteSecureRoutesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inviteSecureRoutesTable,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InviteSecureRoutesTableTableFilterComposer(
                $db: $db,
                $table: $db.inviteSecureRoutesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> environmentSlotLeasesTableRefs(
    Expression<bool> Function($$EnvironmentSlotLeasesTableTableFilterComposer f)
    f,
  ) {
    final $$EnvironmentSlotLeasesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.environmentSlotLeasesTable,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EnvironmentSlotLeasesTableTableFilterComposer(
                $db: $db,
                $table: $db.environmentSlotLeasesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WorkspacesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $WorkspacesTableTable> {
  $$WorkspacesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secretExcludeGlobs => $composableBuilder(
    column: $table.secretExcludeGlobs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewConcurrency => $composableBuilder(
    column: $table.reviewConcurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPublishReview => $composableBuilder(
    column: $table.autoPublishReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectMode => $composableBuilder(
    column: $table.connectMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectUrl => $composableBuilder(
    column: $table.connectUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get githubAppId => $composableBuilder(
    column: $table.githubAppId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get ownerUserId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUserId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkspacesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $WorkspacesTableTable> {
  $$WorkspacesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<String> get secretExcludeGlobs => $composableBuilder(
    column: $table.secretExcludeGlobs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewConcurrency => $composableBuilder(
    column: $table.reviewConcurrency,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoPublishReview => $composableBuilder(
    column: $table.autoPublishReview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get connectMode => $composableBuilder(
    column: $table.connectMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get connectUrl => $composableBuilder(
    column: $table.connectUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get githubAppId => $composableBuilder(
    column: $table.githubAppId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get ownerUserId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUserId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> pairedDevicesTableRefs<T extends Object>(
    Expression<T> Function($$PairedDevicesTableTableAnnotationComposer a) f,
  ) {
    final $$PairedDevicesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.pairedDevicesTable,
          getReferencedColumn: (t) => t.landingWorkspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PairedDevicesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.pairedDevicesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> jobsTableRefs<T extends Object>(
    Expression<T> Function($$JobsTableTableAnnotationComposer a) f,
  ) {
    final $$JobsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobsTable,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.jobsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> placementLogTableRefs<T extends Object>(
    Expression<T> Function($$PlacementLogTableTableAnnotationComposer a) f,
  ) {
    final $$PlacementLogTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.placementLogTable,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlacementLogTableTableAnnotationComposer(
                $db: $db,
                $table: $db.placementLogTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> workspaceRoutesTableRefs<T extends Object>(
    Expression<T> Function($$WorkspaceRoutesTableTableAnnotationComposer a) f,
  ) {
    final $$WorkspaceRoutesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workspaceRoutesTable,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceRoutesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.workspaceRoutesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> inviteSecureRoutesTableRefs<T extends Object>(
    Expression<T> Function($$InviteSecureRoutesTableTableAnnotationComposer a)
    f,
  ) {
    final $$InviteSecureRoutesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inviteSecureRoutesTable,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InviteSecureRoutesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.inviteSecureRoutesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> environmentSlotLeasesTableRefs<T extends Object>(
    Expression<T> Function(
      $$EnvironmentSlotLeasesTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$EnvironmentSlotLeasesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.environmentSlotLeasesTable,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EnvironmentSlotLeasesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.environmentSlotLeasesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WorkspacesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $WorkspacesTableTable,
          WorkspacesTableData,
          $$WorkspacesTableTableFilterComposer,
          $$WorkspacesTableTableOrderingComposer,
          $$WorkspacesTableTableAnnotationComposer,
          $$WorkspacesTableTableCreateCompanionBuilder,
          $$WorkspacesTableTableUpdateCompanionBuilder,
          (WorkspacesTableData, $$WorkspacesTableTableReferences),
          WorkspacesTableData,
          PrefetchHooks Function({
            bool ownerUserId,
            bool pairedDevicesTableRefs,
            bool jobsTableRefs,
            bool placementLogTableRefs,
            bool workspaceRoutesTableRefs,
            bool inviteSecureRoutesTableRefs,
            bool environmentSlotLeasesTableRefs,
          })
        > {
  $$WorkspacesTableTableTableManager(
    _$GlobalDatabase db,
    $WorkspacesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<String> secretExcludeGlobs = const Value.absent(),
                Value<int> reviewConcurrency = const Value.absent(),
                Value<bool> autoPublishReview = const Value.absent(),
                Value<String> connectMode = const Value.absent(),
                Value<String> connectUrl = const Value.absent(),
                Value<String> githubAppId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesTableCompanion(
                id: id,
                name: name,
                logoPath: logoPath,
                ownerUserId: ownerUserId,
                secretExcludeGlobs: secretExcludeGlobs,
                reviewConcurrency: reviewConcurrency,
                autoPublishReview: autoPublishReview,
                connectMode: connectMode,
                connectUrl: connectUrl,
                githubAppId: githubAppId,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> logoPath = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<String> secretExcludeGlobs = const Value.absent(),
                Value<int> reviewConcurrency = const Value.absent(),
                Value<bool> autoPublishReview = const Value.absent(),
                Value<String> connectMode = const Value.absent(),
                Value<String> connectUrl = const Value.absent(),
                Value<String> githubAppId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesTableCompanion.insert(
                id: id,
                name: name,
                logoPath: logoPath,
                ownerUserId: ownerUserId,
                secretExcludeGlobs: secretExcludeGlobs,
                reviewConcurrency: reviewConcurrency,
                autoPublishReview: autoPublishReview,
                connectMode: connectMode,
                connectUrl: connectUrl,
                githubAppId: githubAppId,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkspacesTableTable, WorkspacesTableData>(
                    table,
                  ),
                  $$WorkspacesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ownerUserId = false,
                pairedDevicesTableRefs = false,
                jobsTableRefs = false,
                placementLogTableRefs = false,
                workspaceRoutesTableRefs = false,
                inviteSecureRoutesTableRefs = false,
                environmentSlotLeasesTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pairedDevicesTableRefs) db.pairedDevicesTable,
                    if (jobsTableRefs) db.jobsTable,
                    if (placementLogTableRefs) db.placementLogTable,
                    if (workspaceRoutesTableRefs) db.workspaceRoutesTable,
                    if (inviteSecureRoutesTableRefs) db.inviteSecureRoutesTable,
                    if (environmentSlotLeasesTableRefs)
                      db.environmentSlotLeasesTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ownerUserId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ownerUserId,
                                    referencedTable:
                                        $$WorkspacesTableTableReferences
                                            ._ownerUserIdTable(db),
                                    referencedColumn:
                                        $$WorkspacesTableTableReferences
                                            ._ownerUserIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pairedDevicesTableRefs)
                        await $_getPrefetchedData<
                          WorkspacesTableData,
                          $WorkspacesTableTable,
                          PairedDevicesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableTableReferences
                              ._pairedDevicesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).pairedDevicesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.landingWorkspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (jobsTableRefs)
                        await $_getPrefetchedData<
                          WorkspacesTableData,
                          $WorkspacesTableTable,
                          JobsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableTableReferences
                              ._jobsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).jobsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (placementLogTableRefs)
                        await $_getPrefetchedData<
                          WorkspacesTableData,
                          $WorkspacesTableTable,
                          PlacementLogTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableTableReferences
                              ._placementLogTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).placementLogTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workspaceRoutesTableRefs)
                        await $_getPrefetchedData<
                          WorkspacesTableData,
                          $WorkspacesTableTable,
                          WorkspaceRoutesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableTableReferences
                              ._workspaceRoutesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).workspaceRoutesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inviteSecureRoutesTableRefs)
                        await $_getPrefetchedData<
                          WorkspacesTableData,
                          $WorkspacesTableTable,
                          InviteSecureRoutesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableTableReferences
                              ._inviteSecureRoutesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).inviteSecureRoutesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (environmentSlotLeasesTableRefs)
                        await $_getPrefetchedData<
                          WorkspacesTableData,
                          $WorkspacesTableTable,
                          EnvironmentSlotLeasesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableTableReferences
                              ._environmentSlotLeasesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).environmentSlotLeasesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkspacesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $WorkspacesTableTable,
      WorkspacesTableData,
      $$WorkspacesTableTableFilterComposer,
      $$WorkspacesTableTableOrderingComposer,
      $$WorkspacesTableTableAnnotationComposer,
      $$WorkspacesTableTableCreateCompanionBuilder,
      $$WorkspacesTableTableUpdateCompanionBuilder,
      (WorkspacesTableData, $$WorkspacesTableTableReferences),
      WorkspacesTableData,
      PrefetchHooks Function({
        bool ownerUserId,
        bool pairedDevicesTableRefs,
        bool jobsTableRefs,
        bool placementLogTableRefs,
        bool workspaceRoutesTableRefs,
        bool inviteSecureRoutesTableRefs,
        bool environmentSlotLeasesTableRefs,
      })
    >;
typedef $$UserPreferencesTableTableCreateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      required String userId,
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserPreferencesTableTableUpdateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<String> userId,
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$UserPreferencesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData
        > {
  $$UserPreferencesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _userIdTable(_$GlobalDatabase db) =>
      db.usersTable.createAlias('user_preferences__user_id__users__id');

  $$UsersTableTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserPreferencesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get userId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPreferencesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get userId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPreferencesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get userId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPreferencesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData,
          $$UserPreferencesTableTableFilterComposer,
          $$UserPreferencesTableTableOrderingComposer,
          $$UserPreferencesTableTableAnnotationComposer,
          $$UserPreferencesTableTableCreateCompanionBuilder,
          $$UserPreferencesTableTableUpdateCompanionBuilder,
          (UserPreferencesTableData, $$UserPreferencesTableTableReferences),
          UserPreferencesTableData,
          PrefetchHooks Function({bool userId})
        > {
  $$UserPreferencesTableTableTableManager(
    _$GlobalDatabase db,
    $UserPreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesTableCompanion(
                userId: userId,
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesTableCompanion.insert(
                userId: userId,
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $UserPreferencesTableTable,
                    UserPreferencesTableData
                  >(table),
                  $$UserPreferencesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$UserPreferencesTableTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$UserPreferencesTableTableReferences
                                        ._userIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserPreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $UserPreferencesTableTable,
      UserPreferencesTableData,
      $$UserPreferencesTableTableFilterComposer,
      $$UserPreferencesTableTableOrderingComposer,
      $$UserPreferencesTableTableAnnotationComposer,
      $$UserPreferencesTableTableCreateCompanionBuilder,
      $$UserPreferencesTableTableUpdateCompanionBuilder,
      (UserPreferencesTableData, $$UserPreferencesTableTableReferences),
      UserPreferencesTableData,
      PrefetchHooks Function({bool userId})
    >;
typedef $$PairedDevicesTableTableCreateCompanionBuilder =
    PairedDevicesTableCompanion Function({
      required String id,
      required String userId,
      Value<String?> landingWorkspaceId,
      required String label,
      Value<String> platform,
      required String pskRef,
      Value<String?> remoteFingerprint,
      Value<String> status,
      Value<DateTime> pairedAt,
      Value<DateTime?> lastSeenAt,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });
typedef $$PairedDevicesTableTableUpdateCompanionBuilder =
    PairedDevicesTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> landingWorkspaceId,
      Value<String> label,
      Value<String> platform,
      Value<String> pskRef,
      Value<String?> remoteFingerprint,
      Value<String> status,
      Value<DateTime> pairedAt,
      Value<DateTime?> lastSeenAt,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });

final class $$PairedDevicesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $PairedDevicesTableTable,
          PairedDevicesTableData
        > {
  $$PairedDevicesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _userIdTable(_$GlobalDatabase db) =>
      db.usersTable.createAlias('paired_devices__user_id__users__id');

  $$UsersTableTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WorkspacesTableTable _landingWorkspaceIdTable(_$GlobalDatabase db) =>
      db.workspacesTable.createAlias(
        'paired_devices__landing_workspace_id__workspaces__id',
      );

  $$WorkspacesTableTableProcessedTableManager? get landingWorkspaceId {
    final $_column = $_itemColumn<String>('landing_workspace_id');
    if ($_column == null) return null;
    final manager = $$WorkspacesTableTableTableManager(
      $_db,
      $_db.workspacesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_landingWorkspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkersTableTable, List<WorkersTableData>>
  _workersTableRefsTable(_$GlobalDatabase db) => MultiTypedResultKey.fromTable(
    db.workersTable,
    aliasName: 'paired_devices__id__workers__paired_device_id',
  );

  $$WorkersTableTableProcessedTableManager get workersTableRefs {
    final manager = $$WorkersTableTableTableManager(
      $_db,
      $_db.workersTable,
    ).filter((f) => f.pairedDeviceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workersTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PairedDevicesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $PairedDevicesTableTable> {
  $$PairedDevicesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pskRef => $composableBuilder(
    column: $table.pskRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteFingerprint => $composableBuilder(
    column: $table.remoteFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get userId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkspacesTableTableFilterComposer get landingWorkspaceId {
    final $$WorkspacesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingWorkspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableFilterComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workersTableRefs(
    Expression<bool> Function($$WorkersTableTableFilterComposer f) f,
  ) {
    final $$WorkersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.pairedDeviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableFilterComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PairedDevicesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $PairedDevicesTableTable> {
  $$PairedDevicesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pskRef => $composableBuilder(
    column: $table.pskRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteFingerprint => $composableBuilder(
    column: $table.remoteFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get userId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkspacesTableTableOrderingComposer get landingWorkspaceId {
    final $$WorkspacesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingWorkspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableOrderingComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PairedDevicesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $PairedDevicesTableTable> {
  $$PairedDevicesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get pskRef =>
      $composableBuilder(column: $table.pskRef, builder: (column) => column);

  GeneratedColumn<String> get remoteFingerprint => $composableBuilder(
    column: $table.remoteFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get userId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkspacesTableTableAnnotationComposer get landingWorkspaceId {
    final $$WorkspacesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingWorkspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workersTableRefs<T extends Object>(
    Expression<T> Function($$WorkersTableTableAnnotationComposer a) f,
  ) {
    final $$WorkersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.pairedDeviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PairedDevicesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $PairedDevicesTableTable,
          PairedDevicesTableData,
          $$PairedDevicesTableTableFilterComposer,
          $$PairedDevicesTableTableOrderingComposer,
          $$PairedDevicesTableTableAnnotationComposer,
          $$PairedDevicesTableTableCreateCompanionBuilder,
          $$PairedDevicesTableTableUpdateCompanionBuilder,
          (PairedDevicesTableData, $$PairedDevicesTableTableReferences),
          PairedDevicesTableData,
          PrefetchHooks Function({
            bool userId,
            bool landingWorkspaceId,
            bool workersTableRefs,
          })
        > {
  $$PairedDevicesTableTableTableManager(
    _$GlobalDatabase db,
    $PairedDevicesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PairedDevicesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PairedDevicesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PairedDevicesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> landingWorkspaceId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String> pskRef = const Value.absent(),
                Value<String?> remoteFingerprint = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PairedDevicesTableCompanion(
                id: id,
                userId: userId,
                landingWorkspaceId: landingWorkspaceId,
                label: label,
                platform: platform,
                pskRef: pskRef,
                remoteFingerprint: remoteFingerprint,
                status: status,
                pairedAt: pairedAt,
                lastSeenAt: lastSeenAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> landingWorkspaceId = const Value.absent(),
                required String label,
                Value<String> platform = const Value.absent(),
                required String pskRef,
                Value<String?> remoteFingerprint = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PairedDevicesTableCompanion.insert(
                id: id,
                userId: userId,
                landingWorkspaceId: landingWorkspaceId,
                label: label,
                platform: platform,
                pskRef: pskRef,
                remoteFingerprint: remoteFingerprint,
                status: status,
                pairedAt: pairedAt,
                lastSeenAt: lastSeenAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PairedDevicesTableTable, PairedDevicesTableData>(
                    table,
                  ),
                  $$PairedDevicesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                userId = false,
                landingWorkspaceId = false,
                workersTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workersTableRefs) db.workersTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable:
                                        $$PairedDevicesTableTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$PairedDevicesTableTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (landingWorkspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.landingWorkspaceId,
                                    referencedTable:
                                        $$PairedDevicesTableTableReferences
                                            ._landingWorkspaceIdTable(db),
                                    referencedColumn:
                                        $$PairedDevicesTableTableReferences
                                            ._landingWorkspaceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workersTableRefs)
                        await $_getPrefetchedData<
                          PairedDevicesTableData,
                          $PairedDevicesTableTable,
                          WorkersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PairedDevicesTableTableReferences
                              ._workersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PairedDevicesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).workersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pairedDeviceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PairedDevicesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $PairedDevicesTableTable,
      PairedDevicesTableData,
      $$PairedDevicesTableTableFilterComposer,
      $$PairedDevicesTableTableOrderingComposer,
      $$PairedDevicesTableTableAnnotationComposer,
      $$PairedDevicesTableTableCreateCompanionBuilder,
      $$PairedDevicesTableTableUpdateCompanionBuilder,
      (PairedDevicesTableData, $$PairedDevicesTableTableReferences),
      PairedDevicesTableData,
      PrefetchHooks Function({
        bool userId,
        bool landingWorkspaceId,
        bool workersTableRefs,
      })
    >;
typedef $$RssFeedsTableTableCreateCompanionBuilder =
    RssFeedsTableCompanion Function({
      required String id,
      required String userId,
      required String name,
      required String url,
      Value<String> description,
      Value<String> iconUrl,
      Value<String> userAgent,
      Value<bool> enabled,
      Value<DateTime?> lastFetchedAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RssFeedsTableTableUpdateCompanionBuilder =
    RssFeedsTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String> url,
      Value<String> description,
      Value<String> iconUrl,
      Value<String> userAgent,
      Value<bool> enabled,
      Value<DateTime?> lastFetchedAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RssFeedsTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $RssFeedsTableTable,
          RssFeedsTableData
        > {
  $$RssFeedsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _userIdTable(_$GlobalDatabase db) =>
      db.usersTable.createAlias('rss_feeds__user_id__users__id');

  $$UsersTableTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RssArticlesTableTable, List<RssArticlesTableData>>
  _rssArticlesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rssArticlesTable,
        aliasName: 'rss_feeds__id__rss_articles__feed_id',
      );

  $$RssArticlesTableTableProcessedTableManager get rssArticlesTableRefs {
    final manager = $$RssArticlesTableTableTableManager(
      $_db,
      $_db.rssArticlesTable,
    ).filter((f) => f.feedId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rssArticlesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RssFeedsTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $RssFeedsTableTable> {
  $$RssFeedsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get userId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rssArticlesTableRefs(
    Expression<bool> Function($$RssArticlesTableTableFilterComposer f) f,
  ) {
    final $$RssArticlesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rssArticlesTable,
      getReferencedColumn: (t) => t.feedId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssArticlesTableTableFilterComposer(
            $db: $db,
            $table: $db.rssArticlesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RssFeedsTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $RssFeedsTableTable> {
  $$RssFeedsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get userId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RssFeedsTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $RssFeedsTableTable> {
  $$RssFeedsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<String> get userAgent =>
      $composableBuilder(column: $table.userAgent, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get userId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rssArticlesTableRefs<T extends Object>(
    Expression<T> Function($$RssArticlesTableTableAnnotationComposer a) f,
  ) {
    final $$RssArticlesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rssArticlesTable,
      getReferencedColumn: (t) => t.feedId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssArticlesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.rssArticlesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RssFeedsTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $RssFeedsTableTable,
          RssFeedsTableData,
          $$RssFeedsTableTableFilterComposer,
          $$RssFeedsTableTableOrderingComposer,
          $$RssFeedsTableTableAnnotationComposer,
          $$RssFeedsTableTableCreateCompanionBuilder,
          $$RssFeedsTableTableUpdateCompanionBuilder,
          (RssFeedsTableData, $$RssFeedsTableTableReferences),
          RssFeedsTableData,
          PrefetchHooks Function({bool userId, bool rssArticlesTableRefs})
        > {
  $$RssFeedsTableTableTableManager(
    _$GlobalDatabase db,
    $RssFeedsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RssFeedsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RssFeedsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RssFeedsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> iconUrl = const Value.absent(),
                Value<String> userAgent = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssFeedsTableCompanion(
                id: id,
                userId: userId,
                name: name,
                url: url,
                description: description,
                iconUrl: iconUrl,
                userAgent: userAgent,
                enabled: enabled,
                lastFetchedAt: lastFetchedAt,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                required String url,
                Value<String> description = const Value.absent(),
                Value<String> iconUrl = const Value.absent(),
                Value<String> userAgent = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssFeedsTableCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                url: url,
                description: description,
                iconUrl: iconUrl,
                userAgent: userAgent,
                enabled: enabled,
                lastFetchedAt: lastFetchedAt,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RssFeedsTableTable, RssFeedsTableData>(table),
                  $$RssFeedsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, rssArticlesTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (rssArticlesTableRefs) db.rssArticlesTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable:
                                        $$RssFeedsTableTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$RssFeedsTableTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (rssArticlesTableRefs)
                        await $_getPrefetchedData<
                          RssFeedsTableData,
                          $RssFeedsTableTable,
                          RssArticlesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$RssFeedsTableTableReferences
                              ._rssArticlesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RssFeedsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).rssArticlesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.feedId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RssFeedsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $RssFeedsTableTable,
      RssFeedsTableData,
      $$RssFeedsTableTableFilterComposer,
      $$RssFeedsTableTableOrderingComposer,
      $$RssFeedsTableTableAnnotationComposer,
      $$RssFeedsTableTableCreateCompanionBuilder,
      $$RssFeedsTableTableUpdateCompanionBuilder,
      (RssFeedsTableData, $$RssFeedsTableTableReferences),
      RssFeedsTableData,
      PrefetchHooks Function({bool userId, bool rssArticlesTableRefs})
    >;
typedef $$RssArticlesTableTableCreateCompanionBuilder =
    RssArticlesTableCompanion Function({
      required String id,
      required String feedId,
      required String guid,
      required String title,
      required String link,
      Value<String> summary,
      Value<String> imageUrl,
      Value<String> author,
      Value<DateTime?> publishedAt,
      Value<bool> saved,
      Value<bool> read,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$RssArticlesTableTableUpdateCompanionBuilder =
    RssArticlesTableCompanion Function({
      Value<String> id,
      Value<String> feedId,
      Value<String> guid,
      Value<String> title,
      Value<String> link,
      Value<String> summary,
      Value<String> imageUrl,
      Value<String> author,
      Value<DateTime?> publishedAt,
      Value<bool> saved,
      Value<bool> read,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$RssArticlesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $RssArticlesTableTable,
          RssArticlesTableData
        > {
  $$RssArticlesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RssFeedsTableTable _feedIdTable(_$GlobalDatabase db) =>
      db.rssFeedsTable.createAlias('rss_articles__feed_id__rss_feeds__id');

  $$RssFeedsTableTableProcessedTableManager get feedId {
    final $_column = $_itemColumn<String>('feed_id')!;

    final manager = $$RssFeedsTableTableTableManager(
      $_db,
      $_db.rssFeedsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_feedIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RssArticlesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $RssArticlesTableTable> {
  $$RssArticlesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RssFeedsTableTableFilterComposer get feedId {
    final $$RssFeedsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.feedId,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableFilterComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RssArticlesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $RssArticlesTableTable> {
  $$RssArticlesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RssFeedsTableTableOrderingComposer get feedId {
    final $$RssFeedsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.feedId,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableOrderingComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RssArticlesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $RssArticlesTableTable> {
  $$RssArticlesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get saved =>
      $composableBuilder(column: $table.saved, builder: (column) => column);

  GeneratedColumn<bool> get read =>
      $composableBuilder(column: $table.read, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$RssFeedsTableTableAnnotationComposer get feedId {
    final $$RssFeedsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.feedId,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RssArticlesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $RssArticlesTableTable,
          RssArticlesTableData,
          $$RssArticlesTableTableFilterComposer,
          $$RssArticlesTableTableOrderingComposer,
          $$RssArticlesTableTableAnnotationComposer,
          $$RssArticlesTableTableCreateCompanionBuilder,
          $$RssArticlesTableTableUpdateCompanionBuilder,
          (RssArticlesTableData, $$RssArticlesTableTableReferences),
          RssArticlesTableData,
          PrefetchHooks Function({bool feedId})
        > {
  $$RssArticlesTableTableTableManager(
    _$GlobalDatabase db,
    $RssArticlesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RssArticlesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RssArticlesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RssArticlesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> feedId = const Value.absent(),
                Value<String> guid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> link = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<bool> saved = const Value.absent(),
                Value<bool> read = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssArticlesTableCompanion(
                id: id,
                feedId: feedId,
                guid: guid,
                title: title,
                link: link,
                summary: summary,
                imageUrl: imageUrl,
                author: author,
                publishedAt: publishedAt,
                saved: saved,
                read: read,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String feedId,
                required String guid,
                required String title,
                required String link,
                Value<String> summary = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<bool> saved = const Value.absent(),
                Value<bool> read = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssArticlesTableCompanion.insert(
                id: id,
                feedId: feedId,
                guid: guid,
                title: title,
                link: link,
                summary: summary,
                imageUrl: imageUrl,
                author: author,
                publishedAt: publishedAt,
                saved: saved,
                read: read,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RssArticlesTableTable, RssArticlesTableData>(
                    table,
                  ),
                  $$RssArticlesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({feedId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (feedId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.feedId,
                                referencedTable:
                                    $$RssArticlesTableTableReferences
                                        ._feedIdTable(db),
                                referencedColumn:
                                    $$RssArticlesTableTableReferences
                                        ._feedIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RssArticlesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $RssArticlesTableTable,
      RssArticlesTableData,
      $$RssArticlesTableTableFilterComposer,
      $$RssArticlesTableTableOrderingComposer,
      $$RssArticlesTableTableAnnotationComposer,
      $$RssArticlesTableTableCreateCompanionBuilder,
      $$RssArticlesTableTableUpdateCompanionBuilder,
      (RssArticlesTableData, $$RssArticlesTableTableReferences),
      RssArticlesTableData,
      PrefetchHooks Function({bool feedId})
    >;
typedef $$WorkersTableTableCreateCompanionBuilder =
    WorkersTableCompanion Function({
      required String id,
      required String name,
      Value<String> capsJson,
      Value<String> platform,
      Value<String?> credentialRef,
      Value<String?> pairedDeviceId,
      Value<int> protocolVersion,
      Value<String> status,
      Value<DateTime?> lastHeartbeatAt,
      Value<String?> registeredBy,
      Value<DateTime?> drainedAt,
      Value<DateTime?> revokedAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$WorkersTableTableUpdateCompanionBuilder =
    WorkersTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> capsJson,
      Value<String> platform,
      Value<String?> credentialRef,
      Value<String?> pairedDeviceId,
      Value<int> protocolVersion,
      Value<String> status,
      Value<DateTime?> lastHeartbeatAt,
      Value<String?> registeredBy,
      Value<DateTime?> drainedAt,
      Value<DateTime?> revokedAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$WorkersTableTableReferences
    extends
        BaseReferences<_$GlobalDatabase, $WorkersTableTable, WorkersTableData> {
  $$WorkersTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PairedDevicesTableTable _pairedDeviceIdTable(_$GlobalDatabase db) =>
      db.pairedDevicesTable.createAlias(
        'workers__paired_device_id__paired_devices__id',
      );

  $$PairedDevicesTableTableProcessedTableManager? get pairedDeviceId {
    final $_column = $_itemColumn<String>('paired_device_id');
    if ($_column == null) return null;
    final manager = $$PairedDevicesTableTableTableManager(
      $_db,
      $_db.pairedDevicesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pairedDeviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTableTable _registeredByTable(_$GlobalDatabase db) =>
      db.usersTable.createAlias('workers__registered_by__users__id');

  $$UsersTableTableProcessedTableManager? get registeredBy {
    final $_column = $_itemColumn<String>('registered_by');
    if ($_column == null) return null;
    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_registeredByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$JobsTableTable, List<JobsTableData>>
  _jobsTableRefsTable(_$GlobalDatabase db) => MultiTypedResultKey.fromTable(
    db.jobsTable,
    aliasName: 'workers__id__jobs__worker_id',
  );

  $$JobsTableTableProcessedTableManager get jobsTableRefs {
    final manager = $$JobsTableTableTableManager(
      $_db,
      $_db.jobsTable,
    ).filter((f) => f.workerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_jobsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PlacementLogTableTable,
    List<PlacementLogTableData>
  >
  _placementLogTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.placementLogTable,
        aliasName: 'workers__id__placement_log__worker_id',
      );

  $$PlacementLogTableTableProcessedTableManager get placementLogTableRefs {
    final manager = $$PlacementLogTableTableTableManager(
      $_db,
      $_db.placementLogTable,
    ).filter((f) => f.workerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _placementLogTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkersTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $WorkersTableTable> {
  $$WorkersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capsJson => $composableBuilder(
    column: $table.capsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastHeartbeatAt => $composableBuilder(
    column: $table.lastHeartbeatAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get drainedAt => $composableBuilder(
    column: $table.drainedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PairedDevicesTableTableFilterComposer get pairedDeviceId {
    final $$PairedDevicesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pairedDeviceId,
      referencedTable: $db.pairedDevicesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PairedDevicesTableTableFilterComposer(
            $db: $db,
            $table: $db.pairedDevicesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableTableFilterComposer get registeredBy {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.registeredBy,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> jobsTableRefs(
    Expression<bool> Function($$JobsTableTableFilterComposer f) f,
  ) {
    final $$JobsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobsTable,
      getReferencedColumn: (t) => t.workerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableTableFilterComposer(
            $db: $db,
            $table: $db.jobsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> placementLogTableRefs(
    Expression<bool> Function($$PlacementLogTableTableFilterComposer f) f,
  ) {
    final $$PlacementLogTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placementLogTable,
      getReferencedColumn: (t) => t.workerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacementLogTableTableFilterComposer(
            $db: $db,
            $table: $db.placementLogTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkersTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $WorkersTableTable> {
  $$WorkersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capsJson => $composableBuilder(
    column: $table.capsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastHeartbeatAt => $composableBuilder(
    column: $table.lastHeartbeatAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get drainedAt => $composableBuilder(
    column: $table.drainedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PairedDevicesTableTableOrderingComposer get pairedDeviceId {
    final $$PairedDevicesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pairedDeviceId,
      referencedTable: $db.pairedDevicesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PairedDevicesTableTableOrderingComposer(
            $db: $db,
            $table: $db.pairedDevicesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableTableOrderingComposer get registeredBy {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.registeredBy,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkersTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $WorkersTableTable> {
  $$WorkersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get capsJson =>
      $composableBuilder(column: $table.capsJson, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => column,
  );

  GeneratedColumn<int> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastHeartbeatAt => $composableBuilder(
    column: $table.lastHeartbeatAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get drainedAt =>
      $composableBuilder(column: $table.drainedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PairedDevicesTableTableAnnotationComposer get pairedDeviceId {
    final $$PairedDevicesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.pairedDeviceId,
          referencedTable: $db.pairedDevicesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PairedDevicesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.pairedDevicesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$UsersTableTableAnnotationComposer get registeredBy {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.registeredBy,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> jobsTableRefs<T extends Object>(
    Expression<T> Function($$JobsTableTableAnnotationComposer a) f,
  ) {
    final $$JobsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobsTable,
      getReferencedColumn: (t) => t.workerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.jobsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> placementLogTableRefs<T extends Object>(
    Expression<T> Function($$PlacementLogTableTableAnnotationComposer a) f,
  ) {
    final $$PlacementLogTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.placementLogTable,
          getReferencedColumn: (t) => t.workerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlacementLogTableTableAnnotationComposer(
                $db: $db,
                $table: $db.placementLogTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WorkersTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $WorkersTableTable,
          WorkersTableData,
          $$WorkersTableTableFilterComposer,
          $$WorkersTableTableOrderingComposer,
          $$WorkersTableTableAnnotationComposer,
          $$WorkersTableTableCreateCompanionBuilder,
          $$WorkersTableTableUpdateCompanionBuilder,
          (WorkersTableData, $$WorkersTableTableReferences),
          WorkersTableData,
          PrefetchHooks Function({
            bool pairedDeviceId,
            bool registeredBy,
            bool jobsTableRefs,
            bool placementLogTableRefs,
          })
        > {
  $$WorkersTableTableTableManager(_$GlobalDatabase db, $WorkersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> capsJson = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String?> credentialRef = const Value.absent(),
                Value<String?> pairedDeviceId = const Value.absent(),
                Value<int> protocolVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> lastHeartbeatAt = const Value.absent(),
                Value<String?> registeredBy = const Value.absent(),
                Value<DateTime?> drainedAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkersTableCompanion(
                id: id,
                name: name,
                capsJson: capsJson,
                platform: platform,
                credentialRef: credentialRef,
                pairedDeviceId: pairedDeviceId,
                protocolVersion: protocolVersion,
                status: status,
                lastHeartbeatAt: lastHeartbeatAt,
                registeredBy: registeredBy,
                drainedAt: drainedAt,
                revokedAt: revokedAt,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> capsJson = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String?> credentialRef = const Value.absent(),
                Value<String?> pairedDeviceId = const Value.absent(),
                Value<int> protocolVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> lastHeartbeatAt = const Value.absent(),
                Value<String?> registeredBy = const Value.absent(),
                Value<DateTime?> drainedAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkersTableCompanion.insert(
                id: id,
                name: name,
                capsJson: capsJson,
                platform: platform,
                credentialRef: credentialRef,
                pairedDeviceId: pairedDeviceId,
                protocolVersion: protocolVersion,
                status: status,
                lastHeartbeatAt: lastHeartbeatAt,
                registeredBy: registeredBy,
                drainedAt: drainedAt,
                revokedAt: revokedAt,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkersTableTable, WorkersTableData>(table),
                  $$WorkersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                pairedDeviceId = false,
                registeredBy = false,
                jobsTableRefs = false,
                placementLogTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (jobsTableRefs) db.jobsTable,
                    if (placementLogTableRefs) db.placementLogTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (pairedDeviceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.pairedDeviceId,
                                    referencedTable:
                                        $$WorkersTableTableReferences
                                            ._pairedDeviceIdTable(db),
                                    referencedColumn:
                                        $$WorkersTableTableReferences
                                            ._pairedDeviceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (registeredBy) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.registeredBy,
                                    referencedTable:
                                        $$WorkersTableTableReferences
                                            ._registeredByTable(db),
                                    referencedColumn:
                                        $$WorkersTableTableReferences
                                            ._registeredByTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (jobsTableRefs)
                        await $_getPrefetchedData<
                          WorkersTableData,
                          $WorkersTableTable,
                          JobsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkersTableTableReferences
                              ._jobsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).jobsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (placementLogTableRefs)
                        await $_getPrefetchedData<
                          WorkersTableData,
                          $WorkersTableTable,
                          PlacementLogTableData
                        >(
                          currentTable: table,
                          referencedTable: $$WorkersTableTableReferences
                              ._placementLogTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).placementLogTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $WorkersTableTable,
      WorkersTableData,
      $$WorkersTableTableFilterComposer,
      $$WorkersTableTableOrderingComposer,
      $$WorkersTableTableAnnotationComposer,
      $$WorkersTableTableCreateCompanionBuilder,
      $$WorkersTableTableUpdateCompanionBuilder,
      (WorkersTableData, $$WorkersTableTableReferences),
      WorkersTableData,
      PrefetchHooks Function({
        bool pairedDeviceId,
        bool registeredBy,
        bool jobsTableRefs,
        bool placementLogTableRefs,
      })
    >;
typedef $$JobsTableTableCreateCompanionBuilder =
    JobsTableCompanion Function({
      required String id,
      required String workspaceId,
      required String kind,
      Value<String> specJson,
      Value<String> requiredCapsJson,
      Value<String> preferredCapsJson,
      Value<String> status,
      Value<String?> workerId,
      Value<String?> pinnedWorkerId,
      Value<DateTime?> leaseExpiresAt,
      Value<int> priority,
      Value<String?> submittedBy,
      Value<int> costMicros,
      Value<int> attempts,
      Value<int> maxAttempts,
      Value<int> lastAckedSeq,
      Value<String?> resultJson,
      Value<String?> error,
      Value<String?> agentId,
      Value<String?> conversationId,
      Value<DateTime> createdAt,
      Value<DateTime?> leasedAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$JobsTableTableUpdateCompanionBuilder =
    JobsTableCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> kind,
      Value<String> specJson,
      Value<String> requiredCapsJson,
      Value<String> preferredCapsJson,
      Value<String> status,
      Value<String?> workerId,
      Value<String?> pinnedWorkerId,
      Value<DateTime?> leaseExpiresAt,
      Value<int> priority,
      Value<String?> submittedBy,
      Value<int> costMicros,
      Value<int> attempts,
      Value<int> maxAttempts,
      Value<int> lastAckedSeq,
      Value<String?> resultJson,
      Value<String?> error,
      Value<String?> agentId,
      Value<String?> conversationId,
      Value<DateTime> createdAt,
      Value<DateTime?> leasedAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });

final class $$JobsTableTableReferences
    extends BaseReferences<_$GlobalDatabase, $JobsTableTable, JobsTableData> {
  $$JobsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTableTable _workspaceIdTable(_$GlobalDatabase db) =>
      db.workspacesTable.createAlias('jobs__workspace_id__workspaces__id');

  $$WorkspacesTableTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableTableManager(
      $_db,
      $_db.workspacesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WorkersTableTable _workerIdTable(_$GlobalDatabase db) =>
      db.workersTable.createAlias('jobs__worker_id__workers__id');

  $$WorkersTableTableProcessedTableManager? get workerId {
    final $_column = $_itemColumn<String>('worker_id');
    if ($_column == null) return null;
    final manager = $$WorkersTableTableTableManager(
      $_db,
      $_db.workersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTableTable _submittedByTable(_$GlobalDatabase db) =>
      db.usersTable.createAlias('jobs__submitted_by__users__id');

  $$UsersTableTableProcessedTableManager? get submittedBy {
    final $_column = $_itemColumn<String>('submitted_by');
    if ($_column == null) return null;
    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_submittedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $PlacementLogTableTable,
    List<PlacementLogTableData>
  >
  _placementLogTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.placementLogTable,
        aliasName: 'jobs__id__placement_log__job_id',
      );

  $$PlacementLogTableTableProcessedTableManager get placementLogTableRefs {
    final manager = $$PlacementLogTableTableTableManager(
      $_db,
      $_db.placementLogTable,
    ).filter((f) => f.jobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _placementLogTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$JobsTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $JobsTableTable> {
  $$JobsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specJson => $composableBuilder(
    column: $table.specJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requiredCapsJson => $composableBuilder(
    column: $table.requiredCapsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredCapsJson => $composableBuilder(
    column: $table.preferredCapsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinnedWorkerId => $composableBuilder(
    column: $table.pinnedWorkerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costMicros => $composableBuilder(
    column: $table.costMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leasedAt => $composableBuilder(
    column: $table.leasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableTableFilterComposer get workspaceId {
    final $$WorkspacesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableFilterComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkersTableTableFilterComposer get workerId {
    final $$WorkersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workerId,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableFilterComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableTableFilterComposer get submittedBy {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.submittedBy,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> placementLogTableRefs(
    Expression<bool> Function($$PlacementLogTableTableFilterComposer f) f,
  ) {
    final $$PlacementLogTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placementLogTable,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacementLogTableTableFilterComposer(
            $db: $db,
            $table: $db.placementLogTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JobsTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $JobsTableTable> {
  $$JobsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specJson => $composableBuilder(
    column: $table.specJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requiredCapsJson => $composableBuilder(
    column: $table.requiredCapsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredCapsJson => $composableBuilder(
    column: $table.preferredCapsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinnedWorkerId => $composableBuilder(
    column: $table.pinnedWorkerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costMicros => $composableBuilder(
    column: $table.costMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leasedAt => $composableBuilder(
    column: $table.leasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableTableOrderingComposer get workspaceId {
    final $$WorkspacesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableOrderingComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkersTableTableOrderingComposer get workerId {
    final $$WorkersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workerId,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableOrderingComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableTableOrderingComposer get submittedBy {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.submittedBy,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobsTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $JobsTableTable> {
  $$JobsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get specJson =>
      $composableBuilder(column: $table.specJson, builder: (column) => column);

  GeneratedColumn<String> get requiredCapsJson => $composableBuilder(
    column: $table.requiredCapsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredCapsJson => $composableBuilder(
    column: $table.preferredCapsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get pinnedWorkerId => $composableBuilder(
    column: $table.pinnedWorkerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get costMicros => $composableBuilder(
    column: $table.costMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get leasedAt =>
      $composableBuilder(column: $table.leasedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  $$WorkspacesTableTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkersTableTableAnnotationComposer get workerId {
    final $$WorkersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workerId,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableTableAnnotationComposer get submittedBy {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.submittedBy,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> placementLogTableRefs<T extends Object>(
    Expression<T> Function($$PlacementLogTableTableAnnotationComposer a) f,
  ) {
    final $$PlacementLogTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.placementLogTable,
          getReferencedColumn: (t) => t.jobId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlacementLogTableTableAnnotationComposer(
                $db: $db,
                $table: $db.placementLogTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$JobsTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $JobsTableTable,
          JobsTableData,
          $$JobsTableTableFilterComposer,
          $$JobsTableTableOrderingComposer,
          $$JobsTableTableAnnotationComposer,
          $$JobsTableTableCreateCompanionBuilder,
          $$JobsTableTableUpdateCompanionBuilder,
          (JobsTableData, $$JobsTableTableReferences),
          JobsTableData,
          PrefetchHooks Function({
            bool workspaceId,
            bool workerId,
            bool submittedBy,
            bool placementLogTableRefs,
          })
        > {
  $$JobsTableTableTableManager(_$GlobalDatabase db, $JobsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> specJson = const Value.absent(),
                Value<String> requiredCapsJson = const Value.absent(),
                Value<String> preferredCapsJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                Value<String?> pinnedWorkerId = const Value.absent(),
                Value<DateTime?> leaseExpiresAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> submittedBy = const Value.absent(),
                Value<int> costMicros = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> maxAttempts = const Value.absent(),
                Value<int> lastAckedSeq = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<String?> conversationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> leasedAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsTableCompanion(
                id: id,
                workspaceId: workspaceId,
                kind: kind,
                specJson: specJson,
                requiredCapsJson: requiredCapsJson,
                preferredCapsJson: preferredCapsJson,
                status: status,
                workerId: workerId,
                pinnedWorkerId: pinnedWorkerId,
                leaseExpiresAt: leaseExpiresAt,
                priority: priority,
                submittedBy: submittedBy,
                costMicros: costMicros,
                attempts: attempts,
                maxAttempts: maxAttempts,
                lastAckedSeq: lastAckedSeq,
                resultJson: resultJson,
                error: error,
                agentId: agentId,
                conversationId: conversationId,
                createdAt: createdAt,
                leasedAt: leasedAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String kind,
                Value<String> specJson = const Value.absent(),
                Value<String> requiredCapsJson = const Value.absent(),
                Value<String> preferredCapsJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                Value<String?> pinnedWorkerId = const Value.absent(),
                Value<DateTime?> leaseExpiresAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> submittedBy = const Value.absent(),
                Value<int> costMicros = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> maxAttempts = const Value.absent(),
                Value<int> lastAckedSeq = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<String?> conversationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> leasedAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsTableCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                kind: kind,
                specJson: specJson,
                requiredCapsJson: requiredCapsJson,
                preferredCapsJson: preferredCapsJson,
                status: status,
                workerId: workerId,
                pinnedWorkerId: pinnedWorkerId,
                leaseExpiresAt: leaseExpiresAt,
                priority: priority,
                submittedBy: submittedBy,
                costMicros: costMicros,
                attempts: attempts,
                maxAttempts: maxAttempts,
                lastAckedSeq: lastAckedSeq,
                resultJson: resultJson,
                error: error,
                agentId: agentId,
                conversationId: conversationId,
                createdAt: createdAt,
                leasedAt: leasedAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobsTableTable, JobsTableData>(table),
                  $$JobsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                workerId = false,
                submittedBy = false,
                placementLogTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (placementLogTableRefs) db.placementLogTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable: $$JobsTableTableReferences
                                        ._workspaceIdTable(db),
                                    referencedColumn: $$JobsTableTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (workerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workerId,
                                    referencedTable: $$JobsTableTableReferences
                                        ._workerIdTable(db),
                                    referencedColumn: $$JobsTableTableReferences
                                        ._workerIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (submittedBy) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.submittedBy,
                                    referencedTable: $$JobsTableTableReferences
                                        ._submittedByTable(db),
                                    referencedColumn: $$JobsTableTableReferences
                                        ._submittedByTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (placementLogTableRefs)
                        await $_getPrefetchedData<
                          JobsTableData,
                          $JobsTableTable,
                          PlacementLogTableData
                        >(
                          currentTable: table,
                          referencedTable: $$JobsTableTableReferences
                              ._placementLogTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$JobsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).placementLogTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.jobId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$JobsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $JobsTableTable,
      JobsTableData,
      $$JobsTableTableFilterComposer,
      $$JobsTableTableOrderingComposer,
      $$JobsTableTableAnnotationComposer,
      $$JobsTableTableCreateCompanionBuilder,
      $$JobsTableTableUpdateCompanionBuilder,
      (JobsTableData, $$JobsTableTableReferences),
      JobsTableData,
      PrefetchHooks Function({
        bool workspaceId,
        bool workerId,
        bool submittedBy,
        bool placementLogTableRefs,
      })
    >;
typedef $$PlacementLogTableTableCreateCompanionBuilder =
    PlacementLogTableCompanion Function({
      required String id,
      required String workspaceId,
      required String jobId,
      Value<String?> workerId,
      Value<String> decision,
      Value<String> reason,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$PlacementLogTableTableUpdateCompanionBuilder =
    PlacementLogTableCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> jobId,
      Value<String?> workerId,
      Value<String> decision,
      Value<String> reason,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PlacementLogTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $PlacementLogTableTable,
          PlacementLogTableData
        > {
  $$PlacementLogTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTableTable _workspaceIdTable(_$GlobalDatabase db) => db
      .workspacesTable
      .createAlias('placement_log__workspace_id__workspaces__id');

  $$WorkspacesTableTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableTableManager(
      $_db,
      $_db.workspacesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $JobsTableTable _jobIdTable(_$GlobalDatabase db) =>
      db.jobsTable.createAlias('placement_log__job_id__jobs__id');

  $$JobsTableTableProcessedTableManager get jobId {
    final $_column = $_itemColumn<String>('job_id')!;

    final manager = $$JobsTableTableTableManager(
      $_db,
      $_db.jobsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_jobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WorkersTableTable _workerIdTable(_$GlobalDatabase db) =>
      db.workersTable.createAlias('placement_log__worker_id__workers__id');

  $$WorkersTableTableProcessedTableManager? get workerId {
    final $_column = $_itemColumn<String>('worker_id');
    if ($_column == null) return null;
    final manager = $$WorkersTableTableTableManager(
      $_db,
      $_db.workersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlacementLogTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $PlacementLogTableTable> {
  $$PlacementLogTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableTableFilterComposer get workspaceId {
    final $$WorkspacesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableFilterComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$JobsTableTableFilterComposer get jobId {
    final $$JobsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableTableFilterComposer(
            $db: $db,
            $table: $db.jobsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkersTableTableFilterComposer get workerId {
    final $$WorkersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workerId,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableFilterComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacementLogTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $PlacementLogTableTable> {
  $$PlacementLogTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableTableOrderingComposer get workspaceId {
    final $$WorkspacesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableOrderingComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$JobsTableTableOrderingComposer get jobId {
    final $$JobsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableTableOrderingComposer(
            $db: $db,
            $table: $db.jobsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkersTableTableOrderingComposer get workerId {
    final $$WorkersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workerId,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableOrderingComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacementLogTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $PlacementLogTableTable> {
  $$PlacementLogTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkspacesTableTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$JobsTableTableAnnotationComposer get jobId {
    final $$JobsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.jobsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkersTableTableAnnotationComposer get workerId {
    final $$WorkersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workerId,
      referencedTable: $db.workersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacementLogTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $PlacementLogTableTable,
          PlacementLogTableData,
          $$PlacementLogTableTableFilterComposer,
          $$PlacementLogTableTableOrderingComposer,
          $$PlacementLogTableTableAnnotationComposer,
          $$PlacementLogTableTableCreateCompanionBuilder,
          $$PlacementLogTableTableUpdateCompanionBuilder,
          (PlacementLogTableData, $$PlacementLogTableTableReferences),
          PlacementLogTableData,
          PrefetchHooks Function({bool workspaceId, bool jobId, bool workerId})
        > {
  $$PlacementLogTableTableTableManager(
    _$GlobalDatabase db,
    $PlacementLogTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacementLogTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacementLogTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacementLogTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                Value<String> decision = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacementLogTableCompanion(
                id: id,
                workspaceId: workspaceId,
                jobId: jobId,
                workerId: workerId,
                decision: decision,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String jobId,
                Value<String?> workerId = const Value.absent(),
                Value<String> decision = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacementLogTableCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                jobId: jobId,
                workerId: workerId,
                decision: decision,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlacementLogTableTable, PlacementLogTableData>(
                    table,
                  ),
                  $$PlacementLogTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workspaceId = false, jobId = false, workerId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable:
                                        $$PlacementLogTableTableReferences
                                            ._workspaceIdTable(db),
                                    referencedColumn:
                                        $$PlacementLogTableTableReferences
                                            ._workspaceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (jobId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.jobId,
                                    referencedTable:
                                        $$PlacementLogTableTableReferences
                                            ._jobIdTable(db),
                                    referencedColumn:
                                        $$PlacementLogTableTableReferences
                                            ._jobIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (workerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workerId,
                                    referencedTable:
                                        $$PlacementLogTableTableReferences
                                            ._workerIdTable(db),
                                    referencedColumn:
                                        $$PlacementLogTableTableReferences
                                            ._workerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$PlacementLogTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $PlacementLogTableTable,
      PlacementLogTableData,
      $$PlacementLogTableTableFilterComposer,
      $$PlacementLogTableTableOrderingComposer,
      $$PlacementLogTableTableAnnotationComposer,
      $$PlacementLogTableTableCreateCompanionBuilder,
      $$PlacementLogTableTableUpdateCompanionBuilder,
      (PlacementLogTableData, $$PlacementLogTableTableReferences),
      PlacementLogTableData,
      PrefetchHooks Function({bool workspaceId, bool jobId, bool workerId})
    >;
typedef $$WorkspaceRoutesTableTableCreateCompanionBuilder =
    WorkspaceRoutesTableCompanion Function({
      required String kind,
      required String keyHash,
      required String workspaceId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$WorkspaceRoutesTableTableUpdateCompanionBuilder =
    WorkspaceRoutesTableCompanion Function({
      Value<String> kind,
      Value<String> keyHash,
      Value<String> workspaceId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$WorkspaceRoutesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $WorkspaceRoutesTableTable,
          WorkspaceRoutesTableData
        > {
  $$WorkspaceRoutesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTableTable _workspaceIdTable(_$GlobalDatabase db) => db
      .workspacesTable
      .createAlias('workspace_routes__workspace_id__workspaces__id');

  $$WorkspacesTableTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableTableManager(
      $_db,
      $_db.workspacesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkspaceRoutesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $WorkspaceRoutesTableTable> {
  $$WorkspaceRoutesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyHash => $composableBuilder(
    column: $table.keyHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableTableFilterComposer get workspaceId {
    final $$WorkspacesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableFilterComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkspaceRoutesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $WorkspaceRoutesTableTable> {
  $$WorkspaceRoutesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyHash => $composableBuilder(
    column: $table.keyHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableTableOrderingComposer get workspaceId {
    final $$WorkspacesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableOrderingComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkspaceRoutesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $WorkspaceRoutesTableTable> {
  $$WorkspaceRoutesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get keyHash =>
      $composableBuilder(column: $table.keyHash, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkspacesTableTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkspaceRoutesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $WorkspaceRoutesTableTable,
          WorkspaceRoutesTableData,
          $$WorkspaceRoutesTableTableFilterComposer,
          $$WorkspaceRoutesTableTableOrderingComposer,
          $$WorkspaceRoutesTableTableAnnotationComposer,
          $$WorkspaceRoutesTableTableCreateCompanionBuilder,
          $$WorkspaceRoutesTableTableUpdateCompanionBuilder,
          (WorkspaceRoutesTableData, $$WorkspaceRoutesTableTableReferences),
          WorkspaceRoutesTableData,
          PrefetchHooks Function({bool workspaceId})
        > {
  $$WorkspaceRoutesTableTableTableManager(
    _$GlobalDatabase db,
    $WorkspaceRoutesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspaceRoutesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspaceRoutesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkspaceRoutesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> keyHash = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceRoutesTableCompanion(
                kind: kind,
                keyHash: keyHash,
                workspaceId: workspaceId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String keyHash,
                required String workspaceId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceRoutesTableCompanion.insert(
                kind: kind,
                keyHash: keyHash,
                workspaceId: workspaceId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $WorkspaceRoutesTableTable,
                    WorkspaceRoutesTableData
                  >(table),
                  $$WorkspaceRoutesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable:
                                    $$WorkspaceRoutesTableTableReferences
                                        ._workspaceIdTable(db),
                                referencedColumn:
                                    $$WorkspaceRoutesTableTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkspaceRoutesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $WorkspaceRoutesTableTable,
      WorkspaceRoutesTableData,
      $$WorkspaceRoutesTableTableFilterComposer,
      $$WorkspaceRoutesTableTableOrderingComposer,
      $$WorkspaceRoutesTableTableAnnotationComposer,
      $$WorkspaceRoutesTableTableCreateCompanionBuilder,
      $$WorkspaceRoutesTableTableUpdateCompanionBuilder,
      (WorkspaceRoutesTableData, $$WorkspaceRoutesTableTableReferences),
      WorkspaceRoutesTableData,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $$InviteSecureRoutesTableTableCreateCompanionBuilder =
    InviteSecureRoutesTableCompanion Function({
      required String routeId,
      required String codeHash,
      required String workspaceId,
      Value<int> rowid,
    });
typedef $$InviteSecureRoutesTableTableUpdateCompanionBuilder =
    InviteSecureRoutesTableCompanion Function({
      Value<String> routeId,
      Value<String> codeHash,
      Value<String> workspaceId,
      Value<int> rowid,
    });

final class $$InviteSecureRoutesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $InviteSecureRoutesTableTable,
          InviteSecureRoutesTableData
        > {
  $$InviteSecureRoutesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTableTable _workspaceIdTable(_$GlobalDatabase db) => db
      .workspacesTable
      .createAlias('invite_secure_routes__workspace_id__workspaces__id');

  $$WorkspacesTableTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableTableManager(
      $_db,
      $_db.workspacesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InviteSecureRoutesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $InviteSecureRoutesTableTable> {
  $$InviteSecureRoutesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeHash => $composableBuilder(
    column: $table.codeHash,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableTableFilterComposer get workspaceId {
    final $$WorkspacesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableFilterComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InviteSecureRoutesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $InviteSecureRoutesTableTable> {
  $$InviteSecureRoutesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeHash => $composableBuilder(
    column: $table.codeHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableTableOrderingComposer get workspaceId {
    final $$WorkspacesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableOrderingComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InviteSecureRoutesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $InviteSecureRoutesTableTable> {
  $$InviteSecureRoutesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get routeId =>
      $composableBuilder(column: $table.routeId, builder: (column) => column);

  GeneratedColumn<String> get codeHash =>
      $composableBuilder(column: $table.codeHash, builder: (column) => column);

  $$WorkspacesTableTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InviteSecureRoutesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $InviteSecureRoutesTableTable,
          InviteSecureRoutesTableData,
          $$InviteSecureRoutesTableTableFilterComposer,
          $$InviteSecureRoutesTableTableOrderingComposer,
          $$InviteSecureRoutesTableTableAnnotationComposer,
          $$InviteSecureRoutesTableTableCreateCompanionBuilder,
          $$InviteSecureRoutesTableTableUpdateCompanionBuilder,
          (
            InviteSecureRoutesTableData,
            $$InviteSecureRoutesTableTableReferences,
          ),
          InviteSecureRoutesTableData,
          PrefetchHooks Function({bool workspaceId})
        > {
  $$InviteSecureRoutesTableTableTableManager(
    _$GlobalDatabase db,
    $InviteSecureRoutesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InviteSecureRoutesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InviteSecureRoutesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InviteSecureRoutesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> routeId = const Value.absent(),
                Value<String> codeHash = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InviteSecureRoutesTableCompanion(
                routeId: routeId,
                codeHash: codeHash,
                workspaceId: workspaceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String routeId,
                required String codeHash,
                required String workspaceId,
                Value<int> rowid = const Value.absent(),
              }) => InviteSecureRoutesTableCompanion.insert(
                routeId: routeId,
                codeHash: codeHash,
                workspaceId: workspaceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $InviteSecureRoutesTableTable,
                    InviteSecureRoutesTableData
                  >(table),
                  $$InviteSecureRoutesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable:
                                    $$InviteSecureRoutesTableTableReferences
                                        ._workspaceIdTable(db),
                                referencedColumn:
                                    $$InviteSecureRoutesTableTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InviteSecureRoutesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $InviteSecureRoutesTableTable,
      InviteSecureRoutesTableData,
      $$InviteSecureRoutesTableTableFilterComposer,
      $$InviteSecureRoutesTableTableOrderingComposer,
      $$InviteSecureRoutesTableTableAnnotationComposer,
      $$InviteSecureRoutesTableTableCreateCompanionBuilder,
      $$InviteSecureRoutesTableTableUpdateCompanionBuilder,
      (InviteSecureRoutesTableData, $$InviteSecureRoutesTableTableReferences),
      InviteSecureRoutesTableData,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $$ServerMetaTableTableCreateCompanionBuilder =
    ServerMetaTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$ServerMetaTableTableUpdateCompanionBuilder =
    ServerMetaTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$ServerMetaTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $ServerMetaTableTable> {
  $$ServerMetaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServerMetaTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $ServerMetaTableTable> {
  $$ServerMetaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServerMetaTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $ServerMetaTableTable> {
  $$ServerMetaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$ServerMetaTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $ServerMetaTableTable,
          ServerMetaTableData,
          $$ServerMetaTableTableFilterComposer,
          $$ServerMetaTableTableOrderingComposer,
          $$ServerMetaTableTableAnnotationComposer,
          $$ServerMetaTableTableCreateCompanionBuilder,
          $$ServerMetaTableTableUpdateCompanionBuilder,
          (
            ServerMetaTableData,
            BaseReferences<
              _$GlobalDatabase,
              $ServerMetaTableTable,
              ServerMetaTableData
            >,
          ),
          ServerMetaTableData,
          PrefetchHooks Function()
        > {
  $$ServerMetaTableTableTableManager(
    _$GlobalDatabase db,
    $ServerMetaTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServerMetaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServerMetaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServerMetaTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServerMetaTableCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => ServerMetaTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ServerMetaTableTable, ServerMetaTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$GlobalDatabase,
                    $ServerMetaTableTable,
                    ServerMetaTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServerMetaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $ServerMetaTableTable,
      ServerMetaTableData,
      $$ServerMetaTableTableFilterComposer,
      $$ServerMetaTableTableOrderingComposer,
      $$ServerMetaTableTableAnnotationComposer,
      $$ServerMetaTableTableCreateCompanionBuilder,
      $$ServerMetaTableTableUpdateCompanionBuilder,
      (
        ServerMetaTableData,
        BaseReferences<
          _$GlobalDatabase,
          $ServerMetaTableTable,
          ServerMetaTableData
        >,
      ),
      ServerMetaTableData,
      PrefetchHooks Function()
    >;
typedef $$ServerSettingsTableTableCreateCompanionBuilder =
    ServerSettingsTableCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ServerSettingsTableTableUpdateCompanionBuilder =
    ServerSettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ServerSettingsTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $ServerSettingsTableTable> {
  $$ServerSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServerSettingsTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $ServerSettingsTableTable> {
  $$ServerSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServerSettingsTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $ServerSettingsTableTable> {
  $$ServerSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ServerSettingsTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $ServerSettingsTableTable,
          ServerSettingsTableData,
          $$ServerSettingsTableTableFilterComposer,
          $$ServerSettingsTableTableOrderingComposer,
          $$ServerSettingsTableTableAnnotationComposer,
          $$ServerSettingsTableTableCreateCompanionBuilder,
          $$ServerSettingsTableTableUpdateCompanionBuilder,
          (
            ServerSettingsTableData,
            BaseReferences<
              _$GlobalDatabase,
              $ServerSettingsTableTable,
              ServerSettingsTableData
            >,
          ),
          ServerSettingsTableData,
          PrefetchHooks Function()
        > {
  $$ServerSettingsTableTableTableManager(
    _$GlobalDatabase db,
    $ServerSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServerSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServerSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ServerSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServerSettingsTableCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServerSettingsTableCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ServerSettingsTableTable,
                    ServerSettingsTableData
                  >(table),
                  BaseReferences<
                    _$GlobalDatabase,
                    $ServerSettingsTableTable,
                    ServerSettingsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServerSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $ServerSettingsTableTable,
      ServerSettingsTableData,
      $$ServerSettingsTableTableFilterComposer,
      $$ServerSettingsTableTableOrderingComposer,
      $$ServerSettingsTableTableAnnotationComposer,
      $$ServerSettingsTableTableCreateCompanionBuilder,
      $$ServerSettingsTableTableUpdateCompanionBuilder,
      (
        ServerSettingsTableData,
        BaseReferences<
          _$GlobalDatabase,
          $ServerSettingsTableTable,
          ServerSettingsTableData
        >,
      ),
      ServerSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$SsoConnectionsTableTableCreateCompanionBuilder =
    SsoConnectionsTableCompanion Function({
      required String id,
      required String kind,
      Value<bool> enabled,
      Value<String> issuer,
      Value<String> clientId,
      Value<String> groupsClaim,
      Value<String> idpMetadataXml,
      Value<String> spEntityId,
      Value<String> emailAttribute,
      Value<String> displayNameAttribute,
      Value<String> groupsAttribute,
      Value<String> defaultRole,
      Value<String> groupRoleMap,
      Value<bool> autoMember,
      Value<bool> allowJit,
      Value<bool> allowIdpInitiated,
      Value<bool> wantResponseSigned,
      Value<int> clockSkewSeconds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SsoConnectionsTableTableUpdateCompanionBuilder =
    SsoConnectionsTableCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<bool> enabled,
      Value<String> issuer,
      Value<String> clientId,
      Value<String> groupsClaim,
      Value<String> idpMetadataXml,
      Value<String> spEntityId,
      Value<String> emailAttribute,
      Value<String> displayNameAttribute,
      Value<String> groupsAttribute,
      Value<String> defaultRole,
      Value<String> groupRoleMap,
      Value<bool> autoMember,
      Value<bool> allowJit,
      Value<bool> allowIdpInitiated,
      Value<bool> wantResponseSigned,
      Value<int> clockSkewSeconds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SsoConnectionsTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $SsoConnectionsTableTable> {
  $$SsoConnectionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupsClaim => $composableBuilder(
    column: $table.groupsClaim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idpMetadataXml => $composableBuilder(
    column: $table.idpMetadataXml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spEntityId => $composableBuilder(
    column: $table.spEntityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emailAttribute => $composableBuilder(
    column: $table.emailAttribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayNameAttribute => $composableBuilder(
    column: $table.displayNameAttribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupsAttribute => $composableBuilder(
    column: $table.groupsAttribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultRole => $composableBuilder(
    column: $table.defaultRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupRoleMap => $composableBuilder(
    column: $table.groupRoleMap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoMember => $composableBuilder(
    column: $table.autoMember,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowJit => $composableBuilder(
    column: $table.allowJit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowIdpInitiated => $composableBuilder(
    column: $table.allowIdpInitiated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wantResponseSigned => $composableBuilder(
    column: $table.wantResponseSigned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clockSkewSeconds => $composableBuilder(
    column: $table.clockSkewSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SsoConnectionsTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $SsoConnectionsTableTable> {
  $$SsoConnectionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupsClaim => $composableBuilder(
    column: $table.groupsClaim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idpMetadataXml => $composableBuilder(
    column: $table.idpMetadataXml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spEntityId => $composableBuilder(
    column: $table.spEntityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emailAttribute => $composableBuilder(
    column: $table.emailAttribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayNameAttribute => $composableBuilder(
    column: $table.displayNameAttribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupsAttribute => $composableBuilder(
    column: $table.groupsAttribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultRole => $composableBuilder(
    column: $table.defaultRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupRoleMap => $composableBuilder(
    column: $table.groupRoleMap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoMember => $composableBuilder(
    column: $table.autoMember,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowJit => $composableBuilder(
    column: $table.allowJit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowIdpInitiated => $composableBuilder(
    column: $table.allowIdpInitiated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wantResponseSigned => $composableBuilder(
    column: $table.wantResponseSigned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clockSkewSeconds => $composableBuilder(
    column: $table.clockSkewSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SsoConnectionsTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $SsoConnectionsTableTable> {
  $$SsoConnectionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get issuer =>
      $composableBuilder(column: $table.issuer, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get groupsClaim => $composableBuilder(
    column: $table.groupsClaim,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idpMetadataXml => $composableBuilder(
    column: $table.idpMetadataXml,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spEntityId => $composableBuilder(
    column: $table.spEntityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emailAttribute => $composableBuilder(
    column: $table.emailAttribute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayNameAttribute => $composableBuilder(
    column: $table.displayNameAttribute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupsAttribute => $composableBuilder(
    column: $table.groupsAttribute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultRole => $composableBuilder(
    column: $table.defaultRole,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupRoleMap => $composableBuilder(
    column: $table.groupRoleMap,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoMember => $composableBuilder(
    column: $table.autoMember,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowJit =>
      $composableBuilder(column: $table.allowJit, builder: (column) => column);

  GeneratedColumn<bool> get allowIdpInitiated => $composableBuilder(
    column: $table.allowIdpInitiated,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wantResponseSigned => $composableBuilder(
    column: $table.wantResponseSigned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get clockSkewSeconds => $composableBuilder(
    column: $table.clockSkewSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SsoConnectionsTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $SsoConnectionsTableTable,
          SsoConnectionsTableData,
          $$SsoConnectionsTableTableFilterComposer,
          $$SsoConnectionsTableTableOrderingComposer,
          $$SsoConnectionsTableTableAnnotationComposer,
          $$SsoConnectionsTableTableCreateCompanionBuilder,
          $$SsoConnectionsTableTableUpdateCompanionBuilder,
          (
            SsoConnectionsTableData,
            BaseReferences<
              _$GlobalDatabase,
              $SsoConnectionsTableTable,
              SsoConnectionsTableData
            >,
          ),
          SsoConnectionsTableData,
          PrefetchHooks Function()
        > {
  $$SsoConnectionsTableTableTableManager(
    _$GlobalDatabase db,
    $SsoConnectionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SsoConnectionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SsoConnectionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SsoConnectionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> issuer = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> groupsClaim = const Value.absent(),
                Value<String> idpMetadataXml = const Value.absent(),
                Value<String> spEntityId = const Value.absent(),
                Value<String> emailAttribute = const Value.absent(),
                Value<String> displayNameAttribute = const Value.absent(),
                Value<String> groupsAttribute = const Value.absent(),
                Value<String> defaultRole = const Value.absent(),
                Value<String> groupRoleMap = const Value.absent(),
                Value<bool> autoMember = const Value.absent(),
                Value<bool> allowJit = const Value.absent(),
                Value<bool> allowIdpInitiated = const Value.absent(),
                Value<bool> wantResponseSigned = const Value.absent(),
                Value<int> clockSkewSeconds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SsoConnectionsTableCompanion(
                id: id,
                kind: kind,
                enabled: enabled,
                issuer: issuer,
                clientId: clientId,
                groupsClaim: groupsClaim,
                idpMetadataXml: idpMetadataXml,
                spEntityId: spEntityId,
                emailAttribute: emailAttribute,
                displayNameAttribute: displayNameAttribute,
                groupsAttribute: groupsAttribute,
                defaultRole: defaultRole,
                groupRoleMap: groupRoleMap,
                autoMember: autoMember,
                allowJit: allowJit,
                allowIdpInitiated: allowIdpInitiated,
                wantResponseSigned: wantResponseSigned,
                clockSkewSeconds: clockSkewSeconds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<bool> enabled = const Value.absent(),
                Value<String> issuer = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> groupsClaim = const Value.absent(),
                Value<String> idpMetadataXml = const Value.absent(),
                Value<String> spEntityId = const Value.absent(),
                Value<String> emailAttribute = const Value.absent(),
                Value<String> displayNameAttribute = const Value.absent(),
                Value<String> groupsAttribute = const Value.absent(),
                Value<String> defaultRole = const Value.absent(),
                Value<String> groupRoleMap = const Value.absent(),
                Value<bool> autoMember = const Value.absent(),
                Value<bool> allowJit = const Value.absent(),
                Value<bool> allowIdpInitiated = const Value.absent(),
                Value<bool> wantResponseSigned = const Value.absent(),
                Value<int> clockSkewSeconds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SsoConnectionsTableCompanion.insert(
                id: id,
                kind: kind,
                enabled: enabled,
                issuer: issuer,
                clientId: clientId,
                groupsClaim: groupsClaim,
                idpMetadataXml: idpMetadataXml,
                spEntityId: spEntityId,
                emailAttribute: emailAttribute,
                displayNameAttribute: displayNameAttribute,
                groupsAttribute: groupsAttribute,
                defaultRole: defaultRole,
                groupRoleMap: groupRoleMap,
                autoMember: autoMember,
                allowJit: allowJit,
                allowIdpInitiated: allowIdpInitiated,
                wantResponseSigned: wantResponseSigned,
                clockSkewSeconds: clockSkewSeconds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $SsoConnectionsTableTable,
                    SsoConnectionsTableData
                  >(table),
                  BaseReferences<
                    _$GlobalDatabase,
                    $SsoConnectionsTableTable,
                    SsoConnectionsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SsoConnectionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $SsoConnectionsTableTable,
      SsoConnectionsTableData,
      $$SsoConnectionsTableTableFilterComposer,
      $$SsoConnectionsTableTableOrderingComposer,
      $$SsoConnectionsTableTableAnnotationComposer,
      $$SsoConnectionsTableTableCreateCompanionBuilder,
      $$SsoConnectionsTableTableUpdateCompanionBuilder,
      (
        SsoConnectionsTableData,
        BaseReferences<
          _$GlobalDatabase,
          $SsoConnectionsTableTable,
          SsoConnectionsTableData
        >,
      ),
      SsoConnectionsTableData,
      PrefetchHooks Function()
    >;
typedef $$ManagedActionPoliciesTableTableCreateCompanionBuilder =
    ManagedActionPoliciesTableCompanion Function({
      required String id,
      Value<String?> actionClass,
      Value<String?> commandPrefix,
      Value<String> decision,
      Value<String?> enforcement,
      Value<String?> constraintJson,
      Value<String?> updatedBy,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ManagedActionPoliciesTableTableUpdateCompanionBuilder =
    ManagedActionPoliciesTableCompanion Function({
      Value<String> id,
      Value<String?> actionClass,
      Value<String?> commandPrefix,
      Value<String> decision,
      Value<String?> enforcement,
      Value<String?> constraintJson,
      Value<String?> updatedBy,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ManagedActionPoliciesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $ManagedActionPoliciesTableTable,
          ManagedActionPoliciesTableData
        > {
  $$ManagedActionPoliciesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _updatedByTable(_$GlobalDatabase db) => db.usersTable
      .createAlias('managed_action_policies__updated_by__users__id');

  $$UsersTableTableProcessedTableManager? get updatedBy {
    final $_column = $_itemColumn<String>('updated_by');
    if ($_column == null) return null;
    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_updatedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ManagedActionPoliciesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $ManagedActionPoliciesTableTable> {
  $$ManagedActionPoliciesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionClass => $composableBuilder(
    column: $table.actionClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commandPrefix => $composableBuilder(
    column: $table.commandPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enforcement => $composableBuilder(
    column: $table.enforcement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get constraintJson => $composableBuilder(
    column: $table.constraintJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get updatedBy {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.updatedBy,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ManagedActionPoliciesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $ManagedActionPoliciesTableTable> {
  $$ManagedActionPoliciesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionClass => $composableBuilder(
    column: $table.actionClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commandPrefix => $composableBuilder(
    column: $table.commandPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enforcement => $composableBuilder(
    column: $table.enforcement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get constraintJson => $composableBuilder(
    column: $table.constraintJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get updatedBy {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.updatedBy,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ManagedActionPoliciesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $ManagedActionPoliciesTableTable> {
  $$ManagedActionPoliciesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actionClass => $composableBuilder(
    column: $table.actionClass,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commandPrefix => $composableBuilder(
    column: $table.commandPrefix,
    builder: (column) => column,
  );

  GeneratedColumn<String> get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);

  GeneratedColumn<String> get enforcement => $composableBuilder(
    column: $table.enforcement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get constraintJson => $composableBuilder(
    column: $table.constraintJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get updatedBy {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.updatedBy,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ManagedActionPoliciesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $ManagedActionPoliciesTableTable,
          ManagedActionPoliciesTableData,
          $$ManagedActionPoliciesTableTableFilterComposer,
          $$ManagedActionPoliciesTableTableOrderingComposer,
          $$ManagedActionPoliciesTableTableAnnotationComposer,
          $$ManagedActionPoliciesTableTableCreateCompanionBuilder,
          $$ManagedActionPoliciesTableTableUpdateCompanionBuilder,
          (
            ManagedActionPoliciesTableData,
            $$ManagedActionPoliciesTableTableReferences,
          ),
          ManagedActionPoliciesTableData,
          PrefetchHooks Function({bool updatedBy})
        > {
  $$ManagedActionPoliciesTableTableTableManager(
    _$GlobalDatabase db,
    $ManagedActionPoliciesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManagedActionPoliciesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ManagedActionPoliciesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ManagedActionPoliciesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> actionClass = const Value.absent(),
                Value<String?> commandPrefix = const Value.absent(),
                Value<String> decision = const Value.absent(),
                Value<String?> enforcement = const Value.absent(),
                Value<String?> constraintJson = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManagedActionPoliciesTableCompanion(
                id: id,
                actionClass: actionClass,
                commandPrefix: commandPrefix,
                decision: decision,
                enforcement: enforcement,
                constraintJson: constraintJson,
                updatedBy: updatedBy,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> actionClass = const Value.absent(),
                Value<String?> commandPrefix = const Value.absent(),
                Value<String> decision = const Value.absent(),
                Value<String?> enforcement = const Value.absent(),
                Value<String?> constraintJson = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManagedActionPoliciesTableCompanion.insert(
                id: id,
                actionClass: actionClass,
                commandPrefix: commandPrefix,
                decision: decision,
                enforcement: enforcement,
                constraintJson: constraintJson,
                updatedBy: updatedBy,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ManagedActionPoliciesTableTable,
                    ManagedActionPoliciesTableData
                  >(table),
                  $$ManagedActionPoliciesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({updatedBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (updatedBy) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.updatedBy,
                                referencedTable:
                                    $$ManagedActionPoliciesTableTableReferences
                                        ._updatedByTable(db),
                                referencedColumn:
                                    $$ManagedActionPoliciesTableTableReferences
                                        ._updatedByTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ManagedActionPoliciesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $ManagedActionPoliciesTableTable,
      ManagedActionPoliciesTableData,
      $$ManagedActionPoliciesTableTableFilterComposer,
      $$ManagedActionPoliciesTableTableOrderingComposer,
      $$ManagedActionPoliciesTableTableAnnotationComposer,
      $$ManagedActionPoliciesTableTableCreateCompanionBuilder,
      $$ManagedActionPoliciesTableTableUpdateCompanionBuilder,
      (
        ManagedActionPoliciesTableData,
        $$ManagedActionPoliciesTableTableReferences,
      ),
      ManagedActionPoliciesTableData,
      PrefetchHooks Function({bool updatedBy})
    >;
typedef $$EnvironmentSlotLeasesTableTableCreateCompanionBuilder =
    EnvironmentSlotLeasesTableCompanion Function({
      Value<int> block,
      required int firstPort,
      required int size,
      required String workspaceId,
      required String spaceId,
      required String definitionId,
      Value<String?> poolKey,
      Value<int?> poolSlot,
      required DateTime createdAt,
    });
typedef $$EnvironmentSlotLeasesTableTableUpdateCompanionBuilder =
    EnvironmentSlotLeasesTableCompanion Function({
      Value<int> block,
      Value<int> firstPort,
      Value<int> size,
      Value<String> workspaceId,
      Value<String> spaceId,
      Value<String> definitionId,
      Value<String?> poolKey,
      Value<int?> poolSlot,
      Value<DateTime> createdAt,
    });

final class $$EnvironmentSlotLeasesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $EnvironmentSlotLeasesTableTable,
          EnvironmentSlotLeasesTableData
        > {
  $$EnvironmentSlotLeasesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTableTable _workspaceIdTable(_$GlobalDatabase db) => db
      .workspacesTable
      .createAlias('environment_slot_leases__workspace_id__workspaces__id');

  $$WorkspacesTableTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableTableManager(
      $_db,
      $_db.workspacesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EnvironmentSlotLeasesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $EnvironmentSlotLeasesTableTable> {
  $$EnvironmentSlotLeasesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get block => $composableBuilder(
    column: $table.block,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstPort => $composableBuilder(
    column: $table.firstPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionId => $composableBuilder(
    column: $table.definitionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poolKey => $composableBuilder(
    column: $table.poolKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get poolSlot => $composableBuilder(
    column: $table.poolSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableTableFilterComposer get workspaceId {
    final $$WorkspacesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableFilterComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnvironmentSlotLeasesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $EnvironmentSlotLeasesTableTable> {
  $$EnvironmentSlotLeasesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get block => $composableBuilder(
    column: $table.block,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstPort => $composableBuilder(
    column: $table.firstPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionId => $composableBuilder(
    column: $table.definitionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poolKey => $composableBuilder(
    column: $table.poolKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get poolSlot => $composableBuilder(
    column: $table.poolSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableTableOrderingComposer get workspaceId {
    final $$WorkspacesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableOrderingComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnvironmentSlotLeasesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $EnvironmentSlotLeasesTableTable> {
  $$EnvironmentSlotLeasesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get block =>
      $composableBuilder(column: $table.block, builder: (column) => column);

  GeneratedColumn<int> get firstPort =>
      $composableBuilder(column: $table.firstPort, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  GeneratedColumn<String> get definitionId => $composableBuilder(
    column: $table.definitionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get poolKey =>
      $composableBuilder(column: $table.poolKey, builder: (column) => column);

  GeneratedColumn<int> get poolSlot =>
      $composableBuilder(column: $table.poolSlot, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkspacesTableTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspacesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.workspacesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnvironmentSlotLeasesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $EnvironmentSlotLeasesTableTable,
          EnvironmentSlotLeasesTableData,
          $$EnvironmentSlotLeasesTableTableFilterComposer,
          $$EnvironmentSlotLeasesTableTableOrderingComposer,
          $$EnvironmentSlotLeasesTableTableAnnotationComposer,
          $$EnvironmentSlotLeasesTableTableCreateCompanionBuilder,
          $$EnvironmentSlotLeasesTableTableUpdateCompanionBuilder,
          (
            EnvironmentSlotLeasesTableData,
            $$EnvironmentSlotLeasesTableTableReferences,
          ),
          EnvironmentSlotLeasesTableData,
          PrefetchHooks Function({bool workspaceId})
        > {
  $$EnvironmentSlotLeasesTableTableTableManager(
    _$GlobalDatabase db,
    $EnvironmentSlotLeasesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentSlotLeasesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EnvironmentSlotLeasesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EnvironmentSlotLeasesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> block = const Value.absent(),
                Value<int> firstPort = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> spaceId = const Value.absent(),
                Value<String> definitionId = const Value.absent(),
                Value<String?> poolKey = const Value.absent(),
                Value<int?> poolSlot = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EnvironmentSlotLeasesTableCompanion(
                block: block,
                firstPort: firstPort,
                size: size,
                workspaceId: workspaceId,
                spaceId: spaceId,
                definitionId: definitionId,
                poolKey: poolKey,
                poolSlot: poolSlot,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> block = const Value.absent(),
                required int firstPort,
                required int size,
                required String workspaceId,
                required String spaceId,
                required String definitionId,
                Value<String?> poolKey = const Value.absent(),
                Value<int?> poolSlot = const Value.absent(),
                required DateTime createdAt,
              }) => EnvironmentSlotLeasesTableCompanion.insert(
                block: block,
                firstPort: firstPort,
                size: size,
                workspaceId: workspaceId,
                spaceId: spaceId,
                definitionId: definitionId,
                poolKey: poolKey,
                poolSlot: poolSlot,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $EnvironmentSlotLeasesTableTable,
                    EnvironmentSlotLeasesTableData
                  >(table),
                  $$EnvironmentSlotLeasesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable:
                                    $$EnvironmentSlotLeasesTableTableReferences
                                        ._workspaceIdTable(db),
                                referencedColumn:
                                    $$EnvironmentSlotLeasesTableTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EnvironmentSlotLeasesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $EnvironmentSlotLeasesTableTable,
      EnvironmentSlotLeasesTableData,
      $$EnvironmentSlotLeasesTableTableFilterComposer,
      $$EnvironmentSlotLeasesTableTableOrderingComposer,
      $$EnvironmentSlotLeasesTableTableAnnotationComposer,
      $$EnvironmentSlotLeasesTableTableCreateCompanionBuilder,
      $$EnvironmentSlotLeasesTableTableUpdateCompanionBuilder,
      (
        EnvironmentSlotLeasesTableData,
        $$EnvironmentSlotLeasesTableTableReferences,
      ),
      EnvironmentSlotLeasesTableData,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $$ServerAuditTableTableCreateCompanionBuilder =
    ServerAuditTableCompanion Function({
      required String id,
      required String userId,
      Value<String?> deviceId,
      Value<String?> ip,
      required String op,
      required String argNames,
      required String outcome,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ServerAuditTableTableUpdateCompanionBuilder =
    ServerAuditTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> deviceId,
      Value<String?> ip,
      Value<String> op,
      Value<String> argNames,
      Value<String> outcome,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ServerAuditTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $ServerAuditTableTable> {
  $$ServerAuditTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get argNames => $composableBuilder(
    column: $table.argNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServerAuditTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $ServerAuditTableTable> {
  $$ServerAuditTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get argNames => $composableBuilder(
    column: $table.argNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServerAuditTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $ServerAuditTableTable> {
  $$ServerAuditTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get ip =>
      $composableBuilder(column: $table.ip, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get argNames =>
      $composableBuilder(column: $table.argNames, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ServerAuditTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $ServerAuditTableTable,
          ServerAuditTableData,
          $$ServerAuditTableTableFilterComposer,
          $$ServerAuditTableTableOrderingComposer,
          $$ServerAuditTableTableAnnotationComposer,
          $$ServerAuditTableTableCreateCompanionBuilder,
          $$ServerAuditTableTableUpdateCompanionBuilder,
          (
            ServerAuditTableData,
            BaseReferences<
              _$GlobalDatabase,
              $ServerAuditTableTable,
              ServerAuditTableData
            >,
          ),
          ServerAuditTableData,
          PrefetchHooks Function()
        > {
  $$ServerAuditTableTableTableManager(
    _$GlobalDatabase db,
    $ServerAuditTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServerAuditTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServerAuditTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServerAuditTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> ip = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> argNames = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServerAuditTableCompanion(
                id: id,
                userId: userId,
                deviceId: deviceId,
                ip: ip,
                op: op,
                argNames: argNames,
                outcome: outcome,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> deviceId = const Value.absent(),
                Value<String?> ip = const Value.absent(),
                required String op,
                required String argNames,
                required String outcome,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ServerAuditTableCompanion.insert(
                id: id,
                userId: userId,
                deviceId: deviceId,
                ip: ip,
                op: op,
                argNames: argNames,
                outcome: outcome,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ServerAuditTableTable, ServerAuditTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$GlobalDatabase,
                    $ServerAuditTableTable,
                    ServerAuditTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServerAuditTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $ServerAuditTableTable,
      ServerAuditTableData,
      $$ServerAuditTableTableFilterComposer,
      $$ServerAuditTableTableOrderingComposer,
      $$ServerAuditTableTableAnnotationComposer,
      $$ServerAuditTableTableCreateCompanionBuilder,
      $$ServerAuditTableTableUpdateCompanionBuilder,
      (
        ServerAuditTableData,
        BaseReferences<
          _$GlobalDatabase,
          $ServerAuditTableTable,
          ServerAuditTableData
        >,
      ),
      ServerAuditTableData,
      PrefetchHooks Function()
    >;
typedef $$ServerNoticesTableTableCreateCompanionBuilder =
    ServerNoticesTableCompanion Function({
      required String kind,
      required String subject,
      required String detail,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ServerNoticesTableTableUpdateCompanionBuilder =
    ServerNoticesTableCompanion Function({
      Value<String> kind,
      Value<String> subject,
      Value<String> detail,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ServerNoticesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $ServerNoticesTableTable> {
  $$ServerNoticesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServerNoticesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $ServerNoticesTableTable> {
  $$ServerNoticesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServerNoticesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $ServerNoticesTableTable> {
  $$ServerNoticesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ServerNoticesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $ServerNoticesTableTable,
          ServerNoticesTableData,
          $$ServerNoticesTableTableFilterComposer,
          $$ServerNoticesTableTableOrderingComposer,
          $$ServerNoticesTableTableAnnotationComposer,
          $$ServerNoticesTableTableCreateCompanionBuilder,
          $$ServerNoticesTableTableUpdateCompanionBuilder,
          (
            ServerNoticesTableData,
            BaseReferences<
              _$GlobalDatabase,
              $ServerNoticesTableTable,
              ServerNoticesTableData
            >,
          ),
          ServerNoticesTableData,
          PrefetchHooks Function()
        > {
  $$ServerNoticesTableTableTableManager(
    _$GlobalDatabase db,
    $ServerNoticesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServerNoticesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServerNoticesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServerNoticesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServerNoticesTableCompanion(
                kind: kind,
                subject: subject,
                detail: detail,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String subject,
                required String detail,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ServerNoticesTableCompanion.insert(
                kind: kind,
                subject: subject,
                detail: detail,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ServerNoticesTableTable, ServerNoticesTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$GlobalDatabase,
                    $ServerNoticesTableTable,
                    ServerNoticesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServerNoticesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $ServerNoticesTableTable,
      ServerNoticesTableData,
      $$ServerNoticesTableTableFilterComposer,
      $$ServerNoticesTableTableOrderingComposer,
      $$ServerNoticesTableTableAnnotationComposer,
      $$ServerNoticesTableTableCreateCompanionBuilder,
      $$ServerNoticesTableTableUpdateCompanionBuilder,
      (
        ServerNoticesTableData,
        BaseReferences<
          _$GlobalDatabase,
          $ServerNoticesTableTable,
          ServerNoticesTableData
        >,
      ),
      ServerNoticesTableData,
      PrefetchHooks Function()
    >;
typedef $$AgentPullRequestRequestersTableTableCreateCompanionBuilder =
    AgentPullRequestRequestersTableCompanion Function({
      required String state,
      required String prKey,
      required String userId,
      required DateTime recordedAt,
      Value<int> rowid,
    });
typedef $$AgentPullRequestRequestersTableTableUpdateCompanionBuilder =
    AgentPullRequestRequestersTableCompanion Function({
      Value<String> state,
      Value<String> prKey,
      Value<String> userId,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

final class $$AgentPullRequestRequestersTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $AgentPullRequestRequestersTableTable,
          AgentPullRequestRequestersTableData
        > {
  $$AgentPullRequestRequestersTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _userIdTable(_$GlobalDatabase db) => db.usersTable
      .createAlias('agent_pull_request_requesters__user_id__users__id');

  $$UsersTableTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AgentPullRequestRequestersTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $AgentPullRequestRequestersTableTable> {
  $$AgentPullRequestRequestersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prKey => $composableBuilder(
    column: $table.prKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get userId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AgentPullRequestRequestersTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $AgentPullRequestRequestersTableTable> {
  $$AgentPullRequestRequestersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prKey => $composableBuilder(
    column: $table.prKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get userId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AgentPullRequestRequestersTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $AgentPullRequestRequestersTableTable> {
  $$AgentPullRequestRequestersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get prKey =>
      $composableBuilder(column: $table.prKey, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$UsersTableTableAnnotationComposer get userId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AgentPullRequestRequestersTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $AgentPullRequestRequestersTableTable,
          AgentPullRequestRequestersTableData,
          $$AgentPullRequestRequestersTableTableFilterComposer,
          $$AgentPullRequestRequestersTableTableOrderingComposer,
          $$AgentPullRequestRequestersTableTableAnnotationComposer,
          $$AgentPullRequestRequestersTableTableCreateCompanionBuilder,
          $$AgentPullRequestRequestersTableTableUpdateCompanionBuilder,
          (
            AgentPullRequestRequestersTableData,
            $$AgentPullRequestRequestersTableTableReferences,
          ),
          AgentPullRequestRequestersTableData,
          PrefetchHooks Function({bool userId})
        > {
  $$AgentPullRequestRequestersTableTableTableManager(
    _$GlobalDatabase db,
    $AgentPullRequestRequestersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentPullRequestRequestersTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AgentPullRequestRequestersTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AgentPullRequestRequestersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> state = const Value.absent(),
                Value<String> prKey = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentPullRequestRequestersTableCompanion(
                state: state,
                prKey: prKey,
                userId: userId,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String state,
                required String prKey,
                required String userId,
                required DateTime recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => AgentPullRequestRequestersTableCompanion.insert(
                state: state,
                prKey: prKey,
                userId: userId,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AgentPullRequestRequestersTableTable,
                    AgentPullRequestRequestersTableData
                  >(table),
                  $$AgentPullRequestRequestersTableTableReferences(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$AgentPullRequestRequestersTableTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$AgentPullRequestRequestersTableTableReferences
                                        ._userIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AgentPullRequestRequestersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $AgentPullRequestRequestersTableTable,
      AgentPullRequestRequestersTableData,
      $$AgentPullRequestRequestersTableTableFilterComposer,
      $$AgentPullRequestRequestersTableTableOrderingComposer,
      $$AgentPullRequestRequestersTableTableAnnotationComposer,
      $$AgentPullRequestRequestersTableTableCreateCompanionBuilder,
      $$AgentPullRequestRequestersTableTableUpdateCompanionBuilder,
      (
        AgentPullRequestRequestersTableData,
        $$AgentPullRequestRequestersTableTableReferences,
      ),
      AgentPullRequestRequestersTableData,
      PrefetchHooks Function({bool userId})
    >;

class $GlobalDatabaseManager {
  final _$GlobalDatabase _db;
  $GlobalDatabaseManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(_db, _db.workspacesTable);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(_db, _db.userPreferencesTable);
  $$PairedDevicesTableTableTableManager get pairedDevicesTable =>
      $$PairedDevicesTableTableTableManager(_db, _db.pairedDevicesTable);
  $$RssFeedsTableTableTableManager get rssFeedsTable =>
      $$RssFeedsTableTableTableManager(_db, _db.rssFeedsTable);
  $$RssArticlesTableTableTableManager get rssArticlesTable =>
      $$RssArticlesTableTableTableManager(_db, _db.rssArticlesTable);
  $$WorkersTableTableTableManager get workersTable =>
      $$WorkersTableTableTableManager(_db, _db.workersTable);
  $$JobsTableTableTableManager get jobsTable =>
      $$JobsTableTableTableManager(_db, _db.jobsTable);
  $$PlacementLogTableTableTableManager get placementLogTable =>
      $$PlacementLogTableTableTableManager(_db, _db.placementLogTable);
  $$WorkspaceRoutesTableTableTableManager get workspaceRoutesTable =>
      $$WorkspaceRoutesTableTableTableManager(_db, _db.workspaceRoutesTable);
  $$InviteSecureRoutesTableTableTableManager get inviteSecureRoutesTable =>
      $$InviteSecureRoutesTableTableTableManager(
        _db,
        _db.inviteSecureRoutesTable,
      );
  $$ServerMetaTableTableTableManager get serverMetaTable =>
      $$ServerMetaTableTableTableManager(_db, _db.serverMetaTable);
  $$ServerSettingsTableTableTableManager get serverSettingsTable =>
      $$ServerSettingsTableTableTableManager(_db, _db.serverSettingsTable);
  $$SsoConnectionsTableTableTableManager get ssoConnectionsTable =>
      $$SsoConnectionsTableTableTableManager(_db, _db.ssoConnectionsTable);
  $$ManagedActionPoliciesTableTableTableManager
  get managedActionPoliciesTable =>
      $$ManagedActionPoliciesTableTableTableManager(
        _db,
        _db.managedActionPoliciesTable,
      );
  $$EnvironmentSlotLeasesTableTableTableManager
  get environmentSlotLeasesTable =>
      $$EnvironmentSlotLeasesTableTableTableManager(
        _db,
        _db.environmentSlotLeasesTable,
      );
  $$ServerAuditTableTableTableManager get serverAuditTable =>
      $$ServerAuditTableTableTableManager(_db, _db.serverAuditTable);
  $$ServerNoticesTableTableTableManager get serverNoticesTable =>
      $$ServerNoticesTableTableTableManager(_db, _db.serverNoticesTable);
  $$AgentPullRequestRequestersTableTableTableManager
  get agentPullRequestRequestersTable =>
      $$AgentPullRequestRequestersTableTableTableManager(
        _db,
        _db.agentPullRequestRequestersTable,
      );
}
