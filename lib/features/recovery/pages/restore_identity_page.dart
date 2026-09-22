import 'package:flutter/material.dart';

import '../../../core/crypto/crypto_bridge.dart';
import '../../../core/crypto/crypto_bridge_exception.dart';
import '../../../core/crypto/identity_seed.dart';
import '../../../core/storage/secure_identity_store.dart';
import '../../../core/theme/app_theme.dart';

/// Restauracion de la identidad Semaphore desde la frase de 12 palabras.
///
/// Reemplaza la restauracion automatica que hacia `login_result_page` derivando
/// la identidad de `themis:voter:<sub>`: era comoda, pero implicaba que el
/// servidor (que conoce todos los `sub`) podia derivar la misma identidad y
/// asociar cada voto con su votante.
class RestoreIdentityPage extends StatefulWidget {
  const RestoreIdentityPage({
    super.key,
    required this.secureIdentityStore,
  });

  final SecureIdentityStore secureIdentityStore;

  @override
  State<RestoreIdentityPage> createState() => _RestoreIdentityPageState();
}

class _RestoreIdentityPageState extends State<RestoreIdentityPage> {
  late final CryptoBridge _bridge;
  final _controller = TextEditingController();
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bridge = CryptoBridge();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final input = _controller.text;
    if (!isValidMnemonic(input)) {
      setState(() {
        _error = 'La frase no es válida. Revisa que sean las 12 palabras, '
            'en el mismo orden y sin errores de tipeo.';
      });
      return;
    }

    setState(() {
      _working = true;
      _error = null;
    });

    try {
      final mnemonic = normalizeMnemonic(input);
      final identity = await _bridge.generateIdentity(
        seed: seedFromMnemonic(mnemonic),
      );
      await widget.secureIdentityStore.write(identity.privateKey);
      await widget.secureIdentityStore.writeMnemonic(mnemonic);
      await widget.secureIdentityStore.markMnemonicBackedUp();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CryptoBridgeException catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = 'No se pudo restaurar la identidad: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Restaurar identidad')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _bridge.widget,
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: AppShadows.card,
                ),
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Escribe tus 12 palabras',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Separadas por espacios, en el mismo orden en que las anotaste.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _controller,
                      enabled: !_working,
                      maxLines: 4,
                      minLines: 3,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        hintText: 'palabra1 palabra2 palabra3 ...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border:
                        Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _working ? null : _restore,
                  icon: _working
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_rounded),
                  label: Text(_working ? 'Restaurando...' : 'Restaurar identidad'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
