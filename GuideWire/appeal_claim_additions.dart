// ─── ADD TO claims_event.dart ──────────────────────────────────────────────

class SubmitClaimAppeal extends ClaimsEvent {
  final String claimId;
  final String workerId;
  final String selectedReason;
  final String? additionalContext;

  const SubmitClaimAppeal({
    required this.claimId,
    required this.workerId,
    required this.selectedReason,
    this.additionalContext,
  });

  @override
  List<Object?> get props => [claimId, workerId, selectedReason, additionalContext];
}


// ─── ADD TO claims_bloc.dart — inside on<> registrations ──────────────────

on<SubmitClaimAppeal>(_onSubmitAppeal);

Future<void> _onSubmitAppeal(
  SubmitClaimAppeal event,
  Emitter<ClaimsState> emit,
) async {
  emit(state.copyWith(status: LoadStatus.loading));
  try {
    await _apiService.submitClaimAppeal(
      claimId: event.claimId,
      workerId: event.workerId,
      selectedReason: event.selectedReason,
      additionalContext: event.additionalContext,
    );
    // Refresh claims list so the appealed claim shows updated status
    final updated = await _apiService.getClaims(event.workerId);
    emit(state.copyWith(status: LoadStatus.success, claims: updated));
  } catch (e) {
    emit(state.copyWith(
      status: LoadStatus.failure,
      errorMessage: 'Appeal could not be submitted. Please try again.',
    ));
  }
}


// ─── ADD TO api_service.dart (or wherever HTTP calls live) ────────────────

Future<void> submitClaimAppeal({
  required String claimId,
  required String workerId,
  required String selectedReason,
  String? additionalContext,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/claims/$claimId/appeal'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'worker_id': workerId,
      'selected_reason': selectedReason,
      if (additionalContext != null) 'additional_context': additionalContext,
      'submitted_at': DateTime.now().toIso8601String(),
    }),
  );
  if (response.statusCode != 200) {
    throw Exception('Appeal submission failed: ${response.statusCode}');
  }
}


// ─── ADD TO backend — routes/claims.js ────────────────────────────────────

// POST /claims/:claimId/appeal
router.post('/:claimId/appeal', async (req, res) => {
  const { claimId } = req.params;
  const { worker_id, selected_reason, additional_context, submitted_at } = req.body;

  try {
    // Verify claim exists and belongs to this worker
    const { data: claim, error: fetchError } = await supabase
      .from('claims')
      .select('*')
      .eq('id', claimId)
      .eq('worker_id', worker_id)
      .single();

    if (fetchError || !claim) {
      return res.status(404).json({ error: 'Claim not found' });
    }

    // Only rejected claims can be appealed
    if (claim.status !== 'REJECTED') {
      return res.status(400).json({ error: 'Only rejected claims can be appealed' });
    }

    // Only one appeal per claim
    if (claim.appeal_submitted_at) {
      return res.status(400).json({ error: 'Appeal already submitted for this claim' });
    }

    // Update claim with appeal data
    const { error: updateError } = await supabase
      .from('claims')
      .update({
        status: 'APPEAL_PENDING',
        appeal_selected_reason: selected_reason,
        appeal_context: additional_context || null,
        appeal_submitted_at: submitted_at,
        updated_at: new Date().toISOString(),
      })
      .eq('id', claimId);

    if (updateError) throw updateError;

    // Insert into appeals review queue
    await supabase.from('appeal_queue').insert({
      claim_id: claimId,
      worker_id,
      selected_reason,
      additional_context: additional_context || null,
      submitted_at,
      sla_deadline: new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString(), // 4hr SLA
    });

    res.json({ success: true, message: 'Appeal submitted. Review within 4 hours.' });
  } catch (err) {
    console.error('Appeal submission error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// ─── ADD TO Supabase schema — triggers.sql ────────────────────────────────

-- New appeal_queue table
CREATE TABLE appeal_queue (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  claim_id UUID REFERENCES claims(id) NOT NULL,
  worker_id UUID REFERENCES workers(id) NOT NULL,
  selected_reason TEXT NOT NULL,
  additional_context TEXT,
  submitted_at TIMESTAMPTZ NOT NULL,
  sla_deadline TIMESTAMPTZ NOT NULL,
  reviewed_at TIMESTAMPTZ,
  reviewer_decision TEXT CHECK (reviewer_decision IN ('APPROVED', 'REJECTED')),
  reviewer_note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: workers can only read their own appeal entries
ALTER TABLE appeal_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workers_read_own_appeals" ON appeal_queue
  FOR SELECT USING (worker_id = auth.uid());

-- Add appeal columns to existing claims table
ALTER TABLE claims
  ADD COLUMN IF NOT EXISTS appeal_selected_reason TEXT,
  ADD COLUMN IF NOT EXISTS appeal_context TEXT,
  ADD COLUMN IF NOT EXISTS appeal_submitted_at TIMESTAMPTZ;
