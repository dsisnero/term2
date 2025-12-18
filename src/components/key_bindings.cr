require "../term2"

module Term2
  module Components
    module Key
      # Defines key binding ivars from a hash of name => {keys, help_key, help_desc}
      macro key_bindings(**bindings)
        {% for name, tuple in bindings %}
          @{{ name.id }} = ::Term2::Components::Key::Binding.new({{ tuple[0] }}, {{ tuple[1] }}, {{ tuple[2] }})
          def {{ name.id }} : ::Term2::Components::Key::Binding
            @{{ name.id }}
          end
        {% end %}

        def bindings : Array(::Term2::Components::Key::Binding)
          {% if bindings.size == 0 %}
            [] of ::Term2::Components::Key::Binding
          {% else %}
            [
              {% for name, _ in bindings %}
                @{{ name.id }},
              {% end %}
            ] of ::Term2::Components::Key::Binding
          {% end %}
        end
        nil
      end
    end
  end
end
