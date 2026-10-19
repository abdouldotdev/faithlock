import 'package:faithlock/features/onboarding/models/interactive_action_model.dart';
import 'package:faithlock/shared/widgets/buttons/fast_switch.dart';
import 'package:faithlock/shared/widgets/inputs/fast_text_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget principal pour afficher une action interactive
class InteractiveActionWidget extends StatefulWidget {
  final InteractiveAction action;
  final Function(ActionResult) onActionCompleted;
  final bool isIOS;

  const InteractiveActionWidget({
    super.key,
    required this.action,
    required this.onActionCompleted,
    required this.isIOS,
  });

  @override
  State<InteractiveActionWidget> createState() =>
      _InteractiveActionWidgetState();
}

class _InteractiveActionWidgetState extends State<InteractiveActionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables for action types
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedOptions = [];
  bool _toggleValue = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize state for different action types
    _initializeActionState();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _initializeActionState() {
    switch (widget.action.type) {
      case InteractiveActionType.toggle:
        _toggleValue = widget.action.defaultValue ?? false;
        // Complete action with default value if not required
        if (!widget.action.isRequired) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _completeAction(_toggleValue);
          });
        }
        break;
      case InteractiveActionType.textInput:
      case InteractiveActionType.selection:
      case InteractiveActionType.demo:
      case InteractiveActionType.permission:
      case InteractiveActionType.setup:
        // These require user interaction
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isIOS
                    ? CupertinoColors.systemBackground.resolveFrom(context)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isIOS
                      ? CupertinoColors.separator.resolveFrom(context)
                      : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildActionContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionHeader(),
          const SizedBox(height: 16),
          _buildActionWidget(),
        ],
      ),
    );
  }

  Widget _buildActionHeader() {
    return Row(
      children: [
        if (widget.action.icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  (widget.action.color ?? Colors.blue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.action.icon,
              size: 20,
              color: widget.action.color ?? Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.action.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.isIOS
                      ? CupertinoColors.label.resolveFrom(context)
                      : Colors.grey[900],
                ),
              ),
              if (widget.action.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.action.subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isIOS
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.action.isRequired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'requiredField'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.red[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionWidget() {
    switch (widget.action.type) {
      case InteractiveActionType.toggle:
        return _buildToggleAction();
      case InteractiveActionType.textInput:
        return _buildTextInputAction();
      case InteractiveActionType.selection:
        return _buildSelectionAction();
      case InteractiveActionType.demo:
        return _buildDemoAction();
      case InteractiveActionType.permission:
        return _buildPermissionAction();
      case InteractiveActionType.setup:
        return _buildSetupAction();
    }
  }

  Widget _buildToggleAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (widget.action.color ?? Colors.blue).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.action.toggleDescription != null)
                  Text(
                    widget.action.toggleDescription!,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isIOS
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FastSwitch(
              value: _toggleValue,
              onChanged: (value) {
                setState(() {
                  _toggleValue = value;
                });
                _completeAction(value);
              },
              activeColor: widget.action.color ?? Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FastTextInput(
          controller: _textController,
          hintText: widget.action.placeholder,
          isEnabled: true,
          onChanged: (value) {
            if (value.isNotEmpty) {
              _completeAction(value);
            }
          },
          keyboardType: widget.action.inputType ?? TextInputType.text,
          maxLength: widget.action.maxLength,
          maxLines: 1,
        ),
        if (widget.action.helperText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.action.helperText!,
            style: TextStyle(
              fontSize: 12,
              color: widget.isIOS
                  ? CupertinoColors.secondaryLabel.resolveFrom(context)
                  : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionAction() {
    return Column(
      children: widget.action.options?.map((option) {
            final isSelected = _selectedOptions.contains(option.id);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (widget.action.multiSelect == true) {
                    if (isSelected) {
                      _selectedOptions.remove(option.id);
                    } else {
                      if (widget.action.maxSelection != null &&
                          _selectedOptions.length >=
                              widget.action.maxSelection!) {
                        // Remove first selected if max reached
                        _selectedOptions.removeAt(0);
                      }
                      _selectedOptions.add(option.id);
                    }
                  } else {
                    _selectedOptions.clear();
                    _selectedOptions.add(option.id);
                  }
                });
                _completeAction(_selectedOptions);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (widget.action.color ?? Colors.blue)
                          .withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? widget.action.color ?? Colors.blue
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (option.icon != null) ...[
                      Icon(
                        option.icon,
                        color: isSelected
                            ? widget.action.color ?? Colors.blue
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? widget.action.color ?? Colors.blue
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        widget.isIOS ? CupertinoIcons.checkmark : Icons.check,
                        color: widget.action.color ?? Colors.blue,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }).toList() ??
          [],
    );
  }

  Widget _buildDemoAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (widget.action.color ?? Colors.blue).withValues(alpha: 0.1),
            (widget.action.color ?? Colors.blue).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (widget.action.demoDescription != null) ...[
            Text(
              widget.action.demoDescription!,
              style: TextStyle(
                fontSize: 14,
                color: widget.isIOS
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          if (widget.action.demoWidget != null) widget.action.demoWidget!,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () => _completeAction(true),
              child: Text('tryItNow'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (widget.action.permissionRationale != null) ...[
            Text(
              widget.action.permissionRationale!,
              style: TextStyle(
                fontSize: 14,
                color: widget.isIOS
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () => _requestPermissions(),
              child: Text('authorize'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (widget.action.color ?? Colors.blue).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.settings,
            size: 40,
            color: widget.action.color ?? Colors.blue,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () => _completeAction(true),
              child: Text('configure'.tr),
            ),
          ),
        ],
      ),
    );
  }

  void _completeAction(dynamic value) {
    final result = ActionResult(
      actionId: widget.action.id,
      value: value,
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    widget.onActionCompleted(result);
  }

  void _requestPermissions() async {
    // Complete the action - the controller will handle the actual permission request
    // when _processActionResult is called with InteractiveActionType.permission
    _completeAction(true);
  }
}
