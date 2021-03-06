import 'package:redux/redux.dart';
import 'package:redux_dev_tools/src/actions.dart';
import 'package:redux_dev_tools/src/state.dart';

/// The DevToolsReducer is responsible for taking the dispatched
/// [DevToolsAction]s and updating the [DevToolsState] in response.
///
/// This is not exported and not needed outside of this package.
class DevToolsReducer<S> extends ReducerClass<DevToolsState<S>> {
  final Reducer<S> appReducer;

  DevToolsReducer(this.appReducer);

  @override
  DevToolsState<S> call(DevToolsState<S> state, dynamic action) {
    assert(action is DevToolsAction,
        'When using the Dev Tools, all actions must be wrapped as a DevToolsAction');

    final DevToolsAction devToolsAction = action as DevToolsAction;

    switch (devToolsAction.type) {
      case DevToolsActionTypes.Init:
        final S initialState = appReducer(state.currentAppState, action);

        return new DevToolsState<S>([initialState], <dynamic>[action], 0);

      case DevToolsActionTypes.PerformAction:
        final addToEnd =
            state.currentPosition == state.computedStates.length - 1;

        return new DevToolsState.fromApp(
          state,
          devToolsAction,
          addToEnd
              ? state.computedStates
              : state.computedStates.sublist(0, state.currentPosition + 1),
          addToEnd
              ? state.stagedActions
              : state.stagedActions.sublist(0, state.currentPosition + 1),
          appReducer,
        );

      case DevToolsActionTypes.Reset:
        return new DevToolsState<S>(
          [state.savedState],
          <dynamic>[devToolsAction],
          0,
        );

      case DevToolsActionTypes.Save:
        return new DevToolsState<S>(
            [state.currentAppState], <dynamic>[action], 0);

      case DevToolsActionTypes.JumpToState:
        return new DevToolsState<S>(
          state.computedStates,
          state.stagedActions,
          devToolsAction.position,
        );

      case DevToolsActionTypes.Recompute:
        return new DevToolsState<S>(
          recomputeStates(state.computedStates, state.stagedActions),
          state.stagedActions,
          state.currentPosition,
        );

      default:
        return state;
    }
  }

  List<S> recomputeStates(List<S> computedStates, List<dynamic> stagedActions) {
    final recomputedStates = new List<S>(computedStates.length);
    S currentState = computedStates[0];

    for (int i = 0; i < computedStates.length; i++) {
      final dynamic currentAction = stagedActions[i];
      currentState = appReducer(currentState, currentAction);
      recomputedStates[i] = currentState;
    }

    return recomputedStates;
  }
}
