module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',       // New feature
        'fix',        // Bug fix
        'docs',       // Documentation
        'style',      // Code style changes (formatting, missing semicolons, etc)
        'refactor',   // Code refactoring
        'perf',       // Performance improvements
        'test',       // Test additions or changes
        'ci',         // CI/CD changes
        'chore',      // Build process, dependencies updates
        'revert'      // Revert a previous commit
      ]
    ],
    'type-case': [2, 'always', 'lowerCase'],
    'type-empty': [2, 'never'],
    'scope-case': [2, 'always', 'lowerCase'],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'subject-period': [2, 'never'],
    'header-max-length': [2, 'always', 72],
    'body-leading-blank': [2, 'always'],
    'footer-leading-blank': [2, 'always']
  },
  prompt: {
    questions: {
      type: {
        description: "Select the type of change that you're committing",
        enum: {
          feat: {
            description: 'A new feature',
            title: 'Features'
          },
          fix: {
            description: 'A bug fix',
            title: 'Bug Fixes'
          },
          docs: {
            description: 'Documentation only changes',
            title: 'Documentation'
          },
          style: {
            description: 'Changes that do not affect the meaning of the code (formatting, etc)',
            title: 'Styles'
          },
          refactor: {
            description: 'A code change that neither fixes a bug nor adds a feature',
            title: 'Code Refactoring'
          },
          perf: {
            description: 'A code change that improves performance',
            title: 'Performance Improvements'
          },
          test: {
            description: 'Adding or updating tests',
            title: 'Tests'
          },
          ci: {
            description: 'Changes to CI/CD configuration files and scripts',
            title: 'CI/CD'
          },
          chore: {
            description: 'Build process, dependency updates, or other changes that do not affect code',
            title: 'Chores'
          },
          revert: {
            description: 'Reverts a previous commit',
            title: 'Reverts'
          }
        }
      },
      scope: {
        description: 'What is the scope of this change? (e.g., api, database, ui, auth)'
      },
      subject: {
        description: 'Write a short, imperative present tense description of the change'
      },
      body: {
        description: 'Provide a longer description of the changes. Use "|" to break new line'
      },
      isBreaking: {
        description: 'Are there any breaking changes?',
        type: 'confirm'
      },
      breakingBody: {
        description: 'A BREAKING CHANGE commit requires a body. Please enter a longer description of the commit itself'
      },
      breaking: {
        description: 'Describe the breaking changes'
      },
      isIssueAffected: {
        description: 'Does this change affect any open issues?',
        type: 'confirm'
      },
      issuesBody: {
        description: 'If issues are closed, the commit requires a body. Please enter a longer description of the commit itself'
      },
      issues: {
        description: 'Add issue references (e.g., "fixes #123", "closes #456")'
      }
    }
  }
};
