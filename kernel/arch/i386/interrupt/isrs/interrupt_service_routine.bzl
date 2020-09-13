def _interrupt_service_routine_impl(ctx):
    if ctx.attr.interrupt_service_routine:
        interrupt_service_routine = ctx.attr.interrupt_service_routine
    else:
        interrupt_service_routine = ctx.attr.name

    if ctx.attr.interrupt_service_routine_c:
        interrupt_service_routine_c = ctx.attr.interrupt_service_routine_c
    else:
        interrupt_service_routine_c = interrupt_service_routine + "_c"
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.source_file,
        substitutions = {
            "interrupt_service_routine": interrupt_service_routine,
            "interrupt_service_routine_c": interrupt_service_routine_c,
        },
    )

interrupt_service_routine = rule(
    implementation = _interrupt_service_routine_impl,
    attrs = {
        "_template": attr.label(default = Label("//kernel/arch/i386/interrupt/isrs:isr.S"), allow_single_file = True),
        "interrupt_service_routine_c": attr.string(default = ""),
        "interrupt_service_routine": attr.string(default = ""),
    },
    outputs = {"source_file": "%{name}.S"},
)
