import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_conduce_note.dart';
import 'package:rpsinventory/src/providers/conduce_note_provider.dart';
import 'package:rpsinventory/src/providers/conduce_provider.dart';

class ViewUpdateNote extends ConsumerStatefulWidget {
  final int conduceId;
  final int? conduceNoteId;

  const ViewUpdateNote({
    super.key,
    required this.conduceId,
    this.conduceNoteId,
  });

  static String path = '/note/update';

  @override
  ConsumerState<ViewUpdateNote> createState() => _ViewUpdateNoteState();
}

class _ViewUpdateNoteState extends ConsumerState<ViewUpdateNote> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  ConduceNote? _initialNote;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.conduceNoteId != null;
    if (_isEditing) {
      _loadNoteData();
    }
  }

  Future<void> _loadNoteData() async {
    setState(() {
      _isLoading = true;
    });
    final note = await DBHelper.instance.getConduceNote(widget.conduceNoteId!);
    if (note != null) {
      setState(() {
        _initialNote = note;
        _noteController.text = note.note ?? '';
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitNote() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ref.read(conduceNoteProvider((
        conduceId: widget.conduceId,
        conduceNoteId: widget.conduceNoteId,
        note: _noteController.text,
        )).future);

        // Invalidar el provider del detalle para que se refresque
        ref.invalidate(getConduceProvider(widget.conduceId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nota ${ _isEditing ? 'actualizada' : 'creada'} con éxito'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar la nota: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff0088CC);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Nota' : 'Añadir Nota',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : Text(_isEditing ? 'Actualizar Nota' : 'Guardar Nota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
