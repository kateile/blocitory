import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/widgets.dart';
import 'resource_state.dart';

typedef ItemCreator<B, R> = B Function(R repository);

typedef ResourceMutationBuilder<B> =
    Widget Function(BuildContext context, B cubit);

typedef ResourceMutationOnSuccess<D> =
    void Function(BuildContext context, D data);

typedef ResourceMutationOnError =
    void Function(BuildContext context, String message);

class MutationBuilder<T, B extends Cubit<ResourceState<T>>, R>
    extends StatelessWidget {
  /// This will build a widget that will be shown before mutation like form etc.
  final ResourceMutationBuilder<B> builder;

  /// This will provide bloc
  final ItemCreator<B, R> blocCreator;

  /// If error occurred during mutation
  final ResourceMutationOnError? onError;

  /// What to do when mutation succeed
  final ResourceMutationOnSuccess<T>? onSuccess;

  /// This will be shown via snack bar when mutation succeed
  final String? successMessage;

  /// Custom loading widget
  final Widget? loadingWidget;

  final bool showPopUpSuccess;

  final bool pop;

  const MutationBuilder({
    Key? key,
    required this.builder,
    required this.blocCreator,
    this.onError,
    this.onSuccess,
    this.successMessage,
    this.loadingWidget,
    this.pop = false,
    this.showPopUpSuccess = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<B>(
      create: (context) => blocCreator(RepositoryProvider.of<R>(context)),
      child: BlocConsumer<B, ResourceState>(
        listener: (context, state) {
          //Here onSuccess can have side effects like navigation
          if (state.status == ResourceStatus.success) {
            if (onSuccess != null && state.data != null) {
              onSuccess!(context, state.data);
            }

            if (showPopUpSuccess) {
              displaySuccess(
                context: context,
                message: successMessage ?? 'Action completed successfully!',
                duration: 5,
              );
            }

            if (pop) Navigator.of(context).pop();
          }

          if (state.status == ResourceStatus.error && state.message != null) {
            //If onError is null we use snack bar to show error.
            if (onError != null) {
              onError!(context, state.message!);
            } else {
              displayError(context: context, message: state.message!);
            }
          }
        },
        builder: (context, state) {
          final cubit = BlocProvider.of<B>(context);

          if (state.status == ResourceStatus.loading) {
            return loadingWidget ?? const LoadingIndicator();
          }

          if (state.status == ResourceStatus.error && state.message != null) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final form = builder(context, cubit);
                final children = <Widget>[
                  _MutationErrorBanner(message: state.message!),
                  if (constraints.hasBoundedHeight)
                    Expanded(child: form)
                  else
                    form,
                ];

                return Column(
                  mainAxisSize: constraints.hasBoundedHeight
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  children: children,
                );
              },
            );
          }

          //We always show form when not loading.
          return builder(context, cubit);
        },
      ),
    );
  }
}

class _MutationErrorBanner extends StatelessWidget {
  const _MutationErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade700,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
