"""
Portfolio Forms

Contact form for the portfolio website.
"""

from django import forms


class ContactForm(forms.Form):
    """
    Contact form with validation.
    """
    
    name = forms.CharField(
        max_length=100,
        widget=forms.TextInput(attrs={
            'class': 'form-input',
            'placeholder': 'Il tuo nome',
            'required': True,
        })
    )
    
    email = forms.EmailField(
        widget=forms.EmailInput(attrs={
            'class': 'form-input',
            'placeholder': 'La tua email',
            'required': True,
        })
    )
    
    subject = forms.CharField(
        max_length=200,
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-input',
            'placeholder': 'Oggetto (opzionale)',
        })
    )
    
    message = forms.CharField(
        widget=forms.Textarea(attrs={
            'class': 'form-input form-textarea',
            'placeholder': 'Il tuo messaggio...',
            'rows': 5,
            'required': True,
        })
    )
    
    def clean_message(self):
        """Validate message length."""
        message = self.cleaned_data.get('message')
        if len(message) < 10:
            raise forms.ValidationError('Il messaggio deve essere almeno 10 caratteri.')
        return message
