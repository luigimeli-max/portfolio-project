"""
Context Processors

Global context variables available in all templates.
"""

from django.conf import settings


def site_context(request):
    """
    Add site configuration to all templates.
    """
    return {
        'SITE_CONFIG': getattr(settings, 'SITE_CONFIG', {}),
    }
