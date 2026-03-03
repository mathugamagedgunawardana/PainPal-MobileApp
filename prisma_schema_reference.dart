// This is the Prisma schema file used by the backend
// stored here for reference by the Flutter app developers

/*
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mongodb"
  url      = env("DATABASE_URL")
}

// ----------------------------------------------
// CORE AUTHENTICATION & PROFILE MODELS
// ----------------------------------------------

model User {
  id              String           @id @default(auto()) @map("_id") @db.ObjectId
  email           String           @unique
  passwordHash    String
  role            Role
  createdAt       DateTime         @default(now())
  googleId        String?          @unique
  googleEmail     String?
  googleRefreshToken String?

  // Relations
  patientProfile  PatientProfile?
  doctorProfile   DoctorProfile?
}

model PatientProfile {
  id            String           @id @default(auto()) @map("_id") @db.ObjectId
  userId        String           @unique @db.ObjectId
  user          User             @relation(fields: [userId], references: [id])
  name          String
  dob           DateTime
  gender        String?
  phone         String?
  email         String?
  address       String?
  condition     String?
  ehrRecordId   String?
  createdAt     DateTime         @default(now())

  // Relations
  doctorLinks     PatientDoctorLink[]
  migraineEvents  MigraineEvent[]
  medicationLogs  MedicationLog[]
  medicationGroups MedicationGroup[]
  summaries       DoctorPatientSummary[]
  insights        AIDiagnosticInsight[]
  appointments    Appointment[]
  clinicalNotes   ClinicalNote[]
  communications  Communication[]
  conversations   Conversation[]
}

model DoctorProfile {
  id              String           @id @default(auto()) @map("_id") @db.ObjectId
  userId          String           @unique @db.ObjectId
  user            User             @relation(fields: [userId], references: [id])
  name            String
  specialization  String
  clinicId        String           @db.ObjectId
  clinic          Clinic           @relation(fields: [clinicId], references: [id])

  // Relations
  patientLinks    PatientDoctorLink[]
  summaries       DoctorPatientSummary[]
  medicationGroups MedicationGroup[]
  appointments    Appointment[]
  clinicalNotes   ClinicalNote[]
  communications  Communication[]
  conversations   Conversation[]
}

model Clinic {
  id                String          @id @default(auto()) @map("_id") @db.ObjectId
  name              String
  address           String
  ehrSystemEndpoint String?

  // Relations
  doctors           DoctorProfile[]
}

// ----------------------------------------------
// LINKING & DATA MODELS (Doctor-Facing)
// ----------------------------------------------

model PatientDoctorLink {
  id          String      @id @default(auto()) @map("_id") @db.ObjectId
  doctorId    String      @db.ObjectId
  doctor      DoctorProfile @relation(fields: [doctorId], references: [id])
  patientId   String      @db.ObjectId
  patient     PatientProfile @relation(fields: [patientId], references: [id])
  linkStatus  LinkStatus
  createdAt   DateTime    @default(now())

  @@unique([doctorId, patientId])
}

model MigraineEvent {
  id                 String         @id @default(auto()) @map("_id") @db.ObjectId
  patientId          String         @db.ObjectId
  patient            PatientProfile @relation(fields: [patientId], references: [id])
  startDatetime      DateTime
  severity           Int
  duration           String?
  symptomsLog        String?
  perceivedTriggers  String?
  medicationGroupId  String?        @db.ObjectId
  medicationGroup    MedicationGroup? @relation(fields: [medicationGroupId], references: [id])
  effectiveness      MedicationEffectiveness?
  createdAt          DateTime       @default(now())
}

model MedicationLog {
  id                 String          @id @default(auto()) @map("_id") @db.ObjectId
  patientId          String          @db.ObjectId
  patient            PatientProfile  @relation(fields: [patientId], references: [id])
  medicationGroupId  String?         @db.ObjectId
  medicationGroup    MedicationGroup? @relation(fields: [medicationGroupId], references: [id])
  medicationName     String
  medicationType     MedicationType
  datetimeTaken      DateTime
  dosage             String
  frequency          String?
  adherenceRate      Float?
  createdAt          DateTime        @default(now())
}

// ----------------------------------------------
// AI-GENERATED DOCTOR SUPPORT MODELS
// ----------------------------------------------

model DoctorPatientSummary {
  id                        String         @id @default(auto()) @map("_id") @db.ObjectId
  patientId                 String         @db.ObjectId
  patient                   PatientProfile @relation(fields: [patientId], references: [id])
  doctorId                  String         @db.ObjectId
  doctor                    DoctorProfile  @relation(fields: [doctorId], references: [id])
  generatedDate             DateTime       @default(now())
  summaryType               SummaryType
  structuredSummaryText     String
  avgFrequency              Float
  avgSeverity               Float
  adherenceScore            Float
  treatmentOutcomeAnalysis  String?

  @@unique([patientId, doctorId, generatedDate])
}

model AIDiagnosticInsight {
  id                     String         @id @default(auto()) @map("_id") @db.ObjectId
  patientId              String         @db.ObjectId
  patient                PatientProfile @relation(fields: [patientId], references: [id])
  createdDatetime        DateTime       @default(now())
  diagnosticProbability  Float?
  riskAlertLevel         RiskAlertLevel?
  keyContributors        String[]
}

model Appointment {
  id               String          @id @default(auto()) @map("_id") @db.ObjectId
  patientId        String          @db.ObjectId
  patient          PatientProfile  @relation(fields: [patientId], references: [id])
  doctorId         String          @db.ObjectId
  doctor           DoctorProfile   @relation(fields: [doctorId], references: [id])
  appointmentDate  DateTime
  appointmentType  String
  status           AppointmentStatus
  notes            String?
  createdAt        DateTime        @default(now())
}

model ClinicalNote {
  id               String          @id @default(auto()) @map("_id") @db.ObjectId
  patientId        String          @db.ObjectId
  patient          PatientProfile  @relation(fields: [patientId], references: [id])
  doctorId         String          @db.ObjectId
  doctor           DoctorProfile   @relation(fields: [doctorId], references: [id])
  noteContent      String
  createdAt        DateTime        @default(now())
  updatedAt        DateTime        @updatedAt
}

model Communication {
  id               String          @id @default(auto()) @map("_id") @db.ObjectId
  patientId        String          @db.ObjectId
  patient          PatientProfile  @relation(fields: [patientId], references: [id])
  doctorId         String?         @db.ObjectId
  doctor           DoctorProfile?  @relation(fields: [doctorId], references: [id])
  communicationType String
  message          String
  channel          String
  createdAt        DateTime        @default(now())
}

// ----------------------------------------------
// CHAT (Doctor–Patient messaging)
// ----------------------------------------------

model Conversation {
  id        String        @id @default(auto()) @map("_id") @db.ObjectId
  doctorId  String        @db.ObjectId
  doctor    DoctorProfile @relation(fields: [doctorId], references: [id])
  patientId String        @db.ObjectId
  patient   PatientProfile @relation(fields: [patientId], references: [id])
  createdAt DateTime      @default(now())
  updatedAt DateTime      @updatedAt

  messages  ChatMessage[]

  @@unique([doctorId, patientId])
}

model ChatMessage {
  id             String             @id @default(auto()) @map("_id") @db.ObjectId
  conversationId String             @db.ObjectId
  conversation   Conversation       @relation(fields: [conversationId], references: [id])
  senderRole     ChatSenderRole
  senderUserId   String             @db.ObjectId
  content        String
  createdAt      DateTime           @default(now())
  readAt         DateTime?
}

model MedicationGroup {
  id                String           @id @default(auto()) @map("_id") @db.ObjectId
  patientId         String           @db.ObjectId
  patient           PatientProfile   @relation(fields: [patientId], references: [id])
  doctorId          String           @db.ObjectId
  doctor            DoctorProfile    @relation(fields: [doctorId], references: [id])
  name              String
  description       String?
  groupType         MedicationType
  medications       String[]
  color             String?
  isActive          Boolean          @default(true)
  adherenceRate     Float?
  createdAt         DateTime         @default(now())
  updatedAt         DateTime         @updatedAt

  // Relations
  migraineEvents    MigraineEvent[]
  medicationLogs    MedicationLog[]
}

// ----------------------------------------------
// ENUMERATIONS
// ----------------------------------------------

enum Role {
  ADMIN
  PATIENT
  DOCTOR
}

enum LinkStatus {
  PENDING
  ACTIVE
  REVOKED
}

enum MedicationType {
  PREVENTIVE
  RESCUE
}

enum SummaryType {
  WEEKLY
  MONTHLY
}

enum RiskAlertLevel {
  NONE
  MEDIUM
  HIGH
}

enum AppointmentStatus {
  SCHEDULED
  COMPLETED
  CANCELLED
}

enum MedicationEffectiveness {
  LOW
  MODERATE
  HIGH
}

enum ChatSenderRole {
  DOCTOR
  PATIENT
}
*/

