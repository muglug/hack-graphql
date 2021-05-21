namespace Slack\GraphQL;

use namespace HH\Lib\C;

type ArgumentDefinition = shape(
    'name' => string,
    'type' => Types\IInputType,
    ?'description' => string,
    ?'default_value' => mixed,
    ?'deprecation_reason' => string,
);

interface IFieldDefinition extends Introspection\__Field {
    public function getName(): string;
    public function getType(): Types\IOutputType;
    public function getArguments(): dict<string, ArgumentDefinition>;
}

interface IResolvableFieldDefinition<TParent> extends IFieldDefinition {
    public function resolveAsync(
        TParent $parent,
        vec<\Graphpinator\Parser\Field\Field> $grouped_field,
        ExecutionContext $context,
    ): Awaitable<FieldResult<mixed>>;
}

final class FieldDefinition<TParent, TRet, TResolved> implements IResolvableFieldDefinition<TParent> {
    public function __construct(
        private string $name,
        private Types\IOutputTypeFor<TRet, TResolved> $type,
        private dict<string, ArgumentDefinition> $arguments,
        private (function(
            TParent,
            dict<string, \Graphpinator\Parser\Value\Value>,
            Variables,
        ): Awaitable<TRet>) $resolver,
    ) {}

    public async function resolveAsync(
        TParent $parent,
        vec<\Graphpinator\Parser\Field\Field> $grouped_field,
        ExecutionContext $context,
    ): Awaitable<FieldResult<TResolved>> {
        $resolver = $this->resolver;
        try {
            $value = await $resolver(
                $parent,
                C\firstx($grouped_field)->getArgumentValues(),
                $context->getVariableValues(),
            );
        } catch (UserFacingError $e) {
            return $this->type->resolveError($e);
        } catch (\Throwable $e) {
            return $this->type->resolveError(new FieldResolverError($e));
        }

        return await $this->type->resolveAsync($value, $grouped_field, $context);
    }

    public function getName(): string {
        return $this->name;
    }

    public function getType(): Types\IOutputTypeFor<TRet, TResolved> {
        return $this->type;
    }

    public function getArguments(): dict<string, ArgumentDefinition> {
        return $this->arguments;
    }
}
