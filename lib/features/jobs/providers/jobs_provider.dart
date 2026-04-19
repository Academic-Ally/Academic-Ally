import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../models/job_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Selected job-type filter on the list screen.
/// `null` = All types (default).
class JobsFilterNotifier extends Notifier<JobType?> {
  @override
  JobType? build() => null;
  void set(JobType? type) => state = type;
}

final jobsFilterProvider =
    NotifierProvider<JobsFilterNotifier, JobType?>(JobsFilterNotifier.new);

/// Stream of all jobs, newest first. Client-side filter applies the type
/// selection (cheap — demo dataset is tiny).
final jobsListProvider = StreamProvider<List<JobModel>>((ref) {
  final filter = ref.watch(jobsFilterProvider);

  return FirebaseFirestore.instance
      .collection(FirestorePaths.jobs())
      .orderBy('postedAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) {
    final all = snap.docs.map((d) => JobModel.fromFirestore(d)).toList();
    if (filter == null) return all;
    return all.where((j) => j.type == filter).toList();
  });
});

/// Stream of a single job doc.
final jobDetailProvider =
    StreamProvider.family<JobModel?, String>((ref, jobId) {
  return FirebaseFirestore.instance
      .doc(FirestorePaths.job(jobId))
      .snapshots()
      .map((doc) => doc.exists ? JobModel.fromFirestore(doc) : null);
});

/// Creates a new job post. Returns the auto-generated doc ID.
Future<String?> createJob({
  required WidgetRef ref,
  required String title,
  required String company,
  required String location,
  required JobType type,
  required String description,
  required String applyUrl,
  List<String> tags = const [],
}) async {
  final user = ref.read(currentUserProvider);
  final profile = ref.read(userProfileProvider).value;
  final docRef =
      FirebaseFirestore.instance.collection(FirestorePaths.jobs()).doc();
  final job = JobModel(
    id: docRef.id,
    title: title,
    company: company,
    location: location,
    type: type,
    description: description,
    applyUrl: applyUrl,
    tags: tags,
    postedBy: user?.uid,
    postedByName: profile?.name,
    postedAt: DateTime.now(),
  );
  await docRef.set(job.toMap());
  return docRef.id;
}

Future<void> deleteJob(String jobId) async {
  await FirebaseFirestore.instance.doc(FirestorePaths.job(jobId)).delete();
}

/// One-shot seeder for demo purposes. Writes 6 sample job docs only if the
/// collection is empty. Called from an empty-state "Seed sample jobs"
/// button so demos don't start on a blank slate.
Future<void> seedDemoJobs(WidgetRef ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(FirestorePaths.jobs())
      .limit(1)
      .get();
  if (snap.docs.isNotEmpty) return;

  final samples = _demoSeed();
  for (final s in samples) {
    await createJob(
      ref: ref,
      title: s.title,
      company: s.company,
      location: s.location,
      type: s.type,
      description: s.description,
      applyUrl: s.applyUrl,
      tags: s.tags,
    );
  }
}

class _DemoJob {
  final String title;
  final String company;
  final String location;
  final JobType type;
  final String description;
  final String applyUrl;
  final List<String> tags;
  const _DemoJob(this.title, this.company, this.location, this.type,
      this.description, this.applyUrl, this.tags);
}

List<_DemoJob> _demoSeed() => const [
      _DemoJob(
        'Flutter Developer Intern',
        'Razorpay',
        'Bengaluru · Hybrid',
        JobType.internship,
        'Work on the Razorpay Payments SDK for Flutter. You\'ll pair with senior engineers on open-source contributions and ship production code that millions of businesses depend on.',
        'https://razorpay.com/jobs',
        ['CSE', 'IT', 'Mobile'],
      ),
      _DemoJob(
        'Software Engineer – New Grad',
        'Zoho',
        'Hyderabad · On-site',
        JobType.fullTime,
        'Join Zoho\'s core platform team. Strong CS fundamentals in DSA, DBMS, and networks expected. No prior product experience required — we train the entire first year.',
        'https://zoho.com/careers',
        ['CSE', 'IT'],
      ),
      _DemoJob(
        'ML Research Intern',
        'Microsoft Research India',
        'Bengaluru · On-site',
        JobType.internship,
        'Contribute to ongoing research in large language models and multilingual NLP. Prior publications, strong math background (linear algebra, probability), and Python/PyTorch fluency preferred.',
        'https://microsoft.com/en-us/research/academic-program/internships-india/',
        ['CSE', 'AIML', 'Research'],
      ),
      _DemoJob(
        'Embedded Systems Intern',
        'Bosch Global Software Technologies',
        'Hyderabad · On-site',
        JobType.internship,
        'Work on the ECU firmware for next-gen automotive platforms. C, real-time OS, and CAN protocol exposure ideal. Good fit for ECE/EEE students with hands-on hardware projects.',
        'https://www.bosch.in/careers',
        ['ECE', 'EEE', 'Embedded'],
      ),
      _DemoJob(
        'Frontend Developer',
        'Swiggy',
        'Remote · India',
        JobType.fullTime,
        'Build consumer-facing surfaces of the Swiggy app. You\'ll own end-to-end features from spec to ship with autonomy to make technical choices. TypeScript + React Native experience welcome.',
        'https://careers.swiggy.com',
        ['CSE', 'IT', 'Web'],
      ),
      _DemoJob(
        'QA Engineer — Part-time',
        'Freshworks',
        'Hyderabad · Hybrid',
        JobType.partTime,
        'Support the QA team during final-year semester. 20 hrs/week, flexible schedule. Great fit if you want hands-on software testing experience before graduation.',
        'https://freshworks.com/company/careers',
        ['CSE', 'IT', 'QA'],
      ),
    ];
