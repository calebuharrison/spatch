# Spatch

Organize your logic into predictable, validated tasks.

Spatch is heavily inspired by [ActiveInteraction](https://github.com/AaronLasseigne/active_interaction) and
its precursor, [Mutations](https://github.com/cypriss/mutations).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  spatch:
    github: calebuharrison/spatch
```

Then run:

```sh
shards install
```

## Usage

```crystal
require "spatch"

struct SayHello < Spatch::Task 
  input name : String

  def perform
    puts "Hello, #{name}!"
  end
end

SayHello.run(name: "World")
```

## Tasks

### Task Structure

A task is a `struct` that inherits from `Spatch::Task`:

```crystal
struct MyTask < Spatch::Task
  # define your inputs and outputs here

  def perform
    # write your task logic here
  end
end
```

Tasks are required to define a `perform` method that gets indirectly called by the `run` class method:

```crystal
# Creates an instance of MyTask and performs it
MyTask.run
```

### Inputs

Tasks can optionally define inputs using the `input` macro:

```crystal
struct SayFirstName < Spatch::Task
  input first_name : String

  def perform
    puts @first_name
  end
end
```

Note that an instance variable with the same name as the input is available for use inside the
`perform` method.

Now, if we want to run this task, we need to provide the required input:

```crystal
SayFirstName.run(first_name: "Bob")
```

Of course, you can define as many inputs as you'd like:

```crystal
struct CreateUser < Spatch::Task
  input first_name  : String
  input last_name   : String
  input age         : Int32
  input email       : String
  
  def perform
    User.new(@first_name, @last_name, @age, @email)
  end
end
```

The `run` method expects inputs in the order that they are defined. Of course, you can also use
named arguments or a splatted `NamedTuple`:

```crystal
# All of these will work just fine
CreateUser.run("Bob", "McBobberson", 55, "bob@bob.bob")

CreateUser.run(age: 55, email: "bob@bob.bob", first_name: "Bob", last_name: "McBobberson")

params = { email: "bob@bob.bob", first_name: "Bob", last_name: "McBobberson", age: 55 }
CreateUser.run(**params)
```

This is all well and good, but I'm starting to have some reservations about the validity of that
email address. You can define validation methods for your inputs:

```crystal
struct SendEmail < Spatch::Task
  input email : String

  def validate_email
    @issues.add "cannot end with bob" if @email.ends_with?("bob")
  end

  def perform
    # send an email
  end
end
```

When the `run` method is called on `SendEmail`, the email address will be validated before the
`perform` method is ever called:

```crystal
# Invalid, email cannot end with bob. The `perform` method is never called.
SendEmail.run(email: "bob@bob.bob")

# Perfectly valid, it's a wonderful email address. The `perform` method is called.
SendEmail.run(email: "bob@bob.com")
```

An input is considered valid if no issues were added to it during validation. Multiple issues can be
added to an input and all of them will be reported. In order for validation methods to be recognized and
automatically run, they must be named after an input. Any issues added inside of a validation method will
be associated with the input after which the method is named.

### Outputs

The `run` class method does not return the same thing that `perform` returns. The `perform` method's
return value is discarded. Instead, task outputs can be defined using the `output` macro:

```crystal
struct CreateUser < Spatch::Task
  input first_name  : String
  input last_name   : String
  input email       : String

  output user_id          : Int32
  output user_created_at  : Time

  def perform
    user = User.create(@first_name, @last_name, @email)
    @user_id = user.id
    @user_created_at = user.created_at
  end
end
```

Just like inputs, instance variables of the same name are created and exposed inside of the `perform`
method. By defining them as outputs, the task expects them to be populated with a value of the given
type after `perform` has been called. If outputs are not populated as expected, the task will fail
and the offending outputs will be reported.

## Summaries

When you call the `run` class method on a task, it returns a `Summary`:

```crystal
summary = MyTask.run
```

A task is considered successful if:
- All inputs passed validation (no issues were added),
- There were no uncaught exceptions raised while executing the `perform` method,
- Outputs were populated with values of the expected type at the end of the `perform` method.

You can ask a summary if the task was successful:

```crystal
summary = MyTask.run
if summary.successful?
  # celebrate
end
```

If the task was successful, then task outputs can be accessed directly via getter methods on the
summary. For example, using our `CreateUser` task above:

```crystal
summary = CreateUser.run("Bob", "McBobberson", "bob@bob.com")

if summary.successful?
  puts summary.user_id
  puts summary.user_created_at
end
```

If the task was unsuccessful, then attempting to access its outputs will raise an exception. For
this reason, you should always make sure to call `successful?` before calling the output getters.

Anything that would cause a task to be considered unsuccessful is called an issue. You can retrieve
issues from unsuccessful tasks by calling the `issues` method on the task summary:

```crystal
summary = CreateUser.run("Bob", "McBobberson", "bob@bob.bob")

if summary.successful?
  # celebrate, access all of the outputs you want
else
  puts summary.issues # => { :email => ["cannot end with bob"] }
end
```

Issues are added on a per-field basis. An uncaught exception during execution of the `perform` method
will be added as a `:perform` issue.

There are some other handy methods available for summaries:
```crystal
summary = CreateUser.run(...)

# Retrieve the time that this task began to run.
summary.began_at

# Retrieve the total runtime of the task.
summary.runtime

# Retrieve the time that this task finished.
summary.finished_at
```

## Contributing

1. Fork it ( https://github.com/calebuharrison/spatch/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [calebuharrison](https://github.com/calebuharrison) Caleb Harrison - creator, maintainer
