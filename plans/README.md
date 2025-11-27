# Development Plans

This directory contains development plans for the Term2 project, organized by status.

## Directory Structure

- `active/` - Currently active development plans
- `completed/` - Successfully completed plans
- `backlog/` - Future plans awaiting implementation

## Project Status: ✅ Feature Complete

**Last Updated:** November 25, 2025

The BubbleTea feature parity implementation has been completed. Term2 now provides:

- Full Elm Architecture (Model-Update-View)
- 200+ key sequences across terminal types
- Mouse support (SGR and X10 protocols)
- Focus reporting
- Alternate screen, cursor control
- Components: Spinner, ProgressBar, TextInput, CountdownTimer
- 135 passing tests

## Completed Plans

### [BubbleTea Feature Parity](./completed/bubbletea-feature-parity.md)

**Status**: ✅ Complete
**Completed**: November 25, 2025
**Summary**: Full feature parity with Go BubbleTea library

### Research Plans

- [BubbleTea Research](./completed/bubble_tea_research_plan_v3.md)
- [CML Mastery Research](./completed/cml_mastery_research_plan.md)

## Future Enhancements (Backlog)

- Lipgloss-style styling system
- Additional components (list, table, viewport)
- Theme system
- Plugin architecture

## Plan Format

Each plan follows this structure:

- **Overview**: High-level description and goals
- **Phases**: Breakdown of implementation stages
- **Timeline**: Estimated completion dates
- **Tasks**: Specific implementation items
- **Success Criteria**: Measurable completion metrics
- **Risks**: Potential challenges and mitigation strategies

## Contributing

When starting work on a plan:

1. Move the plan from `backlog/` to `active/`
2. Update the status section with current progress
3. Create detailed implementation tasks
4. Move to `completed/` when all success criteria are met

## Tracking Progress

- Weekly status updates in plan files
- Regular review of success criteria
- Adjustment of timelines based on actual progress
- Documentation of lessons learned
